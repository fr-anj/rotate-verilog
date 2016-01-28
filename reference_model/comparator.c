#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ERROR_NOT_ENOUGH_ARGUMENTS "not enough arguments passed"
#define ERROR_NO_SUCH_FILE	"there is no such file or error in reading file"
#define ERROR_WRONG_IMAGE_FORMAT "file read is not a bitmap image"
#define ERROR_LOADING_FILE "an error occured in loading the image"

#define CW 0
#define CCW 1

#pragma pack(push, 2)
typedef struct bmpfh
{
	short 	signature;
	int 	file_size;
	short 	reserve1;
	short 	reserve2;
	int 	file_offset;
}bmp_fileheader;
#pragma pack(pop)

#pragma pack(push, 2)
typedef struct bmpih
{
	int header_size;
	int width;
	int height;
	short planes;
	short bpp;
	int compression;
	int image_size;
	int xppm;
	int yppm;
	int color_table;
	int color_count;

}bmp_infoheader;
#pragma pack(pop)

typedef struct IMAGE {
    unsigned char *r;
    unsigned char *g;
    unsigned char *b;
}image;

//global variables
int g_height, g_width;

image * load_image (char * filename);
void compare_image (char *filename, image * img1, image * img2);

int main(int argc, char const *argv[]) 
{
    image *img1 = NULL, *img2 = NULL;
    int i;
    char *filename1 = NULL, *filename2 = NULL;
    char *output = NULL;    
    //compare <image1> <image2> <output.csv>
    
    filename1 = (char *) malloc(sizeof(char));
    filename2 = (char *) malloc(sizeof(char));
    output = (char *) malloc(sizeof(char));

    strcpy(filename1, argv[1]);
    strcpy(filename2, argv[2]);
    strcpy(output, argv[3]);

    //load both images
    img1 = load_image(filename1);
    img2 = load_image(filename2);

    compare_image(output, img1, img2);

    //free all allocated memory before end of program
    free(filename1);
    free(filename2);
    free(output);

    return 0;
}

void compare_image (char *filename, image *img1, image *img2)
{
    FILE *header, *output;
    int image_size;
    int i;

    image_size = g_height * g_width;

    printf("create new file \n");

    //create new file
    header = fopen(filename, "w+");

    //write header
    fprintf(header,"index,image 1 R,image 2 R,image 1 G,image 2 G,image 1 B,image 2 B\n");

    fclose(header);

    output = fopen(filename, "a");

    for (i = 0; i < image_size; i++)
    {
	if ((img1->r[i] != img2->r[i]) || (img1->g[i] != img2->g[i]) || (img1->b[i] != img2->b[i]))			
	{
	    fprintf(output, "%d,%x,%x,%x,%x,%x,%x\n", i, img1->r[i],img2->r[i],img1->g[i],img2->g[i],img1->b[i],img2->b[i]);
	}
    }

    fclose(output);
}

image * load_image (char *filename)
{
	FILE *buf = NULL;
	image *img = NULL;
	unsigned char *imgbuf = NULL;
	bmp_fileheader fileheader;
	bmp_infoheader infoheader;
	int i,index_r = 0,index_g = 0,index_b = 0;
	int image_size = 0;

	buf = fopen(filename, "rb");
	if (buf == NULL)
	{
		printf("%s\n", ERROR_NO_SUCH_FILE);
		return NULL;
	}

	if ((fread(&fileheader, sizeof(bmp_fileheader), 1, buf)) == 0)
	    printf("fileheader error");

	if (fileheader.signature != 0x4d42)
	{
		fclose(buf);
		printf("%s\n", ERROR_WRONG_IMAGE_FORMAT);
		return NULL;		
	}else 
	{
	    printf("correct image format\n");
	}

	if (fread(&infoheader, sizeof(bmp_infoheader), 1, buf) == 0)
	    printf("infoheader error");

	/*DEBUG
	printf("input image:\n");
	printf("height = %d\n",infoheader.height);
	printf("width = %d\n",infoheader.width);
	*/
	image_size = infoheader.height * infoheader.width;
	
	g_height = infoheader.height;
	g_width = infoheader.width;

	/*DEBUG
	printf("image size = %d\n",image_size);
	*/

	fseek(buf, fileheader.file_offset, SEEK_SET);
	
	imgbuf = malloc(infoheader.image_size);

	if (fread(imgbuf, infoheader.image_size, sizeof(unsigned char), buf) == 0)
	    printf("%s\n",ERROR_LOADING_FILE);

	img = malloc(sizeof(image));
	img->r = malloc(sizeof(unsigned char) * image_size);
	img->g = malloc(sizeof(unsigned char) * image_size);
	img->b = malloc(sizeof(unsigned char) * image_size);

	for (i = 0; i < infoheader.image_size; i++) 
	{
	    if (i % 3 == 0)
	    {
		img->b[index_b++] = imgbuf[i];
	    }
	    else if (i % 3 == 1)
	    {
		img->g[index_g++] = imgbuf[i];	
	    } else 
	    {
		img->r[index_r++] = imgbuf[i];
	    }
	}

	/*DEBUG 
	printf("%d vs %d\n",image_size, infoheader.image_size );

	print_px(img, 0);
	print_px(img, 1);
	print_px(img, 2);
	*/

	if (img == NULL)
	{
		free(img);
		fclose(buf);
		printf("%s\n", ERROR_LOADING_FILE);
		return NULL;
	}

	return img;
}
