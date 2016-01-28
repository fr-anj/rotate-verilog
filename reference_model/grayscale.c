/*date: january 
 *
 * */

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
void print_px (image *img, int index);
void create_image (char *filename, image *img);

void print_px (image *img, int index)
{
    printf("[%d] r: %x g: %x b: %x\n",index,img->r[index] ,img->g[index] ,img->b[index]);
    
}

void create_image (char *filename, image *img)
{
    FILE *output = NULL;
    int i, index = 0;
    unsigned char *imgbuf;

    imgbuf = malloc(g_infoheader.image_size);

    output = fopen(filename, "w+");

    if (fwrite(&g_fileheader, sizeof(bmp_fileheader), 1, output) == 0)
	printf("fileheader write error");

    if (fwrite(&g_infoheader, sizeof(bmp_infoheader), 1, output) == 0)
	printf("infoheader write error");

    for (i = 0; i < g_infoheader.image_size; i += 3)
    {
	imgbuf[i] = img->b[index];
	imgbuf[i + 1] = img->g[index];
	imgbuf[i + 2] = img->r[index];
	index++;
    }

    if(fwrite(imgbuf, sizeof(unsigned int), g_infoheader.image_size, output) == 0)
	printf("image write error");

    free(imgbuf);
    fclose(output);
}

int main(int argc, char const *argv[])
{
    double r_linear, g_linear, b_linear;
    int r, g, b;
    image *img;

    //load image and separate R, G, and B 
    //of every pixel
    

    //convert sRGB to linear grayscale
    r_linear = sRGB_to_linear (
    
    return 0;   
}

double sRGB_to_linear (double x)
{
    if (x < 0.04045)
	return x / 12.92;
    else
	return pow((x + 0.055) / 1.055, 2.4);
}


