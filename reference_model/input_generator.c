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

//function prototypes
image * load_image (char *filename);
int image_height (char *filename);
int image_width (char *filename);
void generate (char *filename, image *img, int height, int width);

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

        generate(new_filename, img, image_height(filename), image_width(filename)); 

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

	image_size = infoheader.height * infoheader.width;
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

	if (img == NULL)
	{
		free(img);
		fclose(buf);
		printf("%s\n", ERROR_LOADING_FILE);
		return NULL;
	}

	fclose(buf);

	return img;
}

int image_height (char *filename)
{
    FILE *buf;
    buf = fopen(filename, "r");
    bmp_fileheader fileheader;
    bmp_infoheader infoheader;
    
    if (buf == NULL)
    {
	printf("%s\n", ERROR_NO_SUCH_FILE);
	return 0;
    }

    if ((fread(&fileheader, sizeof(bmp_fileheader), 1, buf)) == 0)
	printf("fileheader error");

    if (fileheader.signature != 0x4d42)
    {
	    fclose(buf);
	    printf("%s\n", ERROR_WRONG_IMAGE_FORMAT);
	    return 0;		
    }else 
    {
	printf("correct image format\n");
    }

    if (fread(&infoheader, sizeof(bmp_infoheader), 1, buf) == 0)
    {	
	printf("infoheader error");
	return 0;
    }
    fclose(buf);
    return infoheader.height;
}

int image_width (char *filename)
{
    FILE *buf;
    buf = fopen(filename, "r");
    bmp_fileheader fileheader;
    bmp_infoheader infoheader;
    
    if (buf == NULL)
    {
	printf("%s\n", ERROR_NO_SUCH_FILE);
	return 0;
    }

    if ((fread(&fileheader, sizeof(bmp_fileheader), 1, buf)) == 0)
	printf("fileheader error");

    if (fileheader.signature != 0x4d42)
    {
	    fclose(buf);
	    printf("%s\n", ERROR_WRONG_IMAGE_FORMAT);
	    return 0;		
    }else 
    {
	printf("correct image format\n");
    }

    if (fread(&infoheader, sizeof(bmp_infoheader), 1, buf) == 0)
    {	
	printf("infoheader error");
	return 0;
    }
    fclose (buf);
    return infoheader.width;
}

void generate (char *filename, image *img, int height, int width)
{
    int total, i, index;
    FILE *outbuf;
    unsigned char *imgbuf;

    total = height * width;
    outbuf = fopen( filename, "w");
    imgbuf = malloc(total);

    printf("size: %d", total);
    i = 0;
    for (index = 0; index < total; index += 3)
    {
	imgbuf[index] = img->b[i];
	imgbuf[index + 1] = img->g[i];
	imgbuf[index + 2] = img->r[i];
	i++;
    }

    if(fwrite(imgbuf, sizeof(unsigned char), total, outbuf) == 0)
	printf("image write error");

    fclose (outbuf);
    free (imgbuf);
}
