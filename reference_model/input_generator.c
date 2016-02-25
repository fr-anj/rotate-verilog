//image generator 
//generate image readable by the testbench 

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

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
int g_height;
int g_width;
bmp_infoheader g_infoheader;
bmp_fileheader g_fileheader;

//function prototypes
image * load_image (char *filename);
void create_file (char *filename, image *img);

void create_file (char *filename, image *img)
{
    FILE *output = NULL;
    int i; 
    
    output = fopen(filename, "w+");

    for (i = 0; i < g_infoheader.image_size; i += 3)
    {
        fprintf(output, "%x\n%x\n%x\n", img->b[i], img->g[i + 1], img->r[i + 2]);
    }

    fclose(output);
}

int main(int argc, char const *argv[])
{
	char *filename = NULL;
	char *new_filename = NULL;

	image *img = NULL;
	FILE *new_file = NULL;

	bmp_infoheader infoheader;

	//rotate <source_image> <destination_image> <degrees>
	if (argc < 3)	
	{
		printf("%s\n", ERROR_NOT_ENOUGH_ARGUMENTS);
		return 1;
	} 
        else 
	{
                filename = malloc(sizeof(char *));
		new_filename = malloc(sizeof(char *));

		strcpy(filename, argv[1]);
		strcpy(new_filename, argv[2]);
        }

        img = load_image(filename); //extract rgb data 

        create_file (new_filename, img); 

	return 0;
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

	g_fileheader = fileheader;
	g_infoheader = infoheader;

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

