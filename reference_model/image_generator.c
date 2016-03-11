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

image create_image (int height, int width)
{
    int total_size;
    int index;
    image *new_img;

    total_size = height * width;

    new_img = malloc(sizeof(image*) * total_size);
    
    for (index = 0; index < total_size; index++)
    {	
	img->b = rand() % 256;
	img->g = rand() % 256;
	img->r = rand() % 256;
    }
}

int main (int argc, char const *argv[])
{
    char *filename;
    char *c_height, *c_width;
    int height, width;
    int index, total_size;
    FILE *file;

    image *img;

    bmp_infoheader infoheader;

    if (argc < 2)
    {
	printf("%s", ERROR_NOT_ENOUGH_ARGUMENTS);
	return 1;
    }else 
    {
	filename = malloc(sizeof(char *));
	c_height = malloc(sizeof(char *));
	c_width = malloc(sizeof(char *));

	strcpy(filename, argv[1]);
	strcpy(height, argv[2]);
	strcpy(width, arg[3]);	

	height = atoi(c_height);
	width = atoi(c_width);
	index = height * width;

	//create raw image with random data
	img = create_image(height, width);

	//create file
	file = fopen(filename, "w");
	for (index = 0; index < total_size; index++)
	{
	    //write to file
	}
    }

    free(filename);
    free(c_height);
    free(c_width);

    return 0;
}
