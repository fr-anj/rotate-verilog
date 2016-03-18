#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

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

image *create_image (int height, int width)
{
    int total_size;
    int index;
    time_t t;
    image *new_img;
printf("DEBUG:inside create_image()\n");
    srand((unsigned) time(&t));
    total_size = height * width;
printf("DEBUG:inside allocating mem for image\n");
	new_img = malloc(sizeof(image));
	new_img->r = malloc(sizeof(unsigned char) * total_size);
	new_img->g = malloc(sizeof(unsigned char) * total_size);
	new_img->b = malloc(sizeof(unsigned char) * total_size);
printf("DEBUG:allocation done\n");
    for (index = 0; index < total_size; index++)
    {	
	new_img->b[index] = rand() % 256;
	new_img->g[index] = rand() % 256;
	new_img->r[index] = rand() % 256;
    }
printf("DEBUG:returning *new_img from create_image()\n");
    return new_img;
}

int main (int argc, char const *argv[])
{
    int index = 0;
    int i = 0;
    char *filename;
    char *c_height, *c_width;
    bmp_fileheader fileheader;
    bmp_infoheader infoheader;
    int height, width, total_size;
    FILE *file;
    image *img;
    unsigned char *imgbuf;
    //header
    int extrabytes,pad;
    //debug
    time_t t;
    struct tm * ti;

time(&t);
ti = localtime(&t);
printf("DEBUG:start time %s", asctime(ti));

printf("DEBUG:inside main()\n");

    if (argc < 2)
    {
	printf("%s", ERROR_NOT_ENOUGH_ARGUMENTS);
	return 1;
    }else 
    {
    	filename = malloc(sizeof(char *));
	c_height = malloc(sizeof(char *));
	c_width = malloc(sizeof(char *));
printf("DEBUG:allocating mem for parsing\n");
	strcpy(filename, argv[1]);
	strcpy(c_height, argv[2]);
	strcpy(c_width, argv[3]);	
printf("DEBUG:done allocating mem for parsing\n");
    	height = atoi(c_height);
	width = atoi(c_width);
	total_size = height * width;

	extrabytes = 4 - ((width * 3) % 4);  
	if (extrabytes == 4)
	    extrabytes = 0;
	pad = ((width * 3) + extrabytes) * height;

printf("DEBUG:parsing\n");
	//create raw image with random data
	img = create_image(height, width);
printf("DEBUG:done create_image()\n");
	//fill in file header
	fileheader.signature = 0x4d42;
	fileheader.file_size = pad + 54;
	fileheader.file_offset = 54;
	fileheader.reserve1 = 0;
	fileheader.reserve2 = 0;
	//modify infoheader
	infoheader.height = height;
	infoheader.width = width;
	infoheader.header_size = 40;
	infoheader.image_size = pad;
	infoheader.planes = 1;
	infoheader.bpp = 24;
	infoheader.compression = 0;
	infoheader.xppm = 0;
	infoheader.yppm = 0;
	infoheader.color_table = 0;
	infoheader.color_count = 0;
printf("DEBUG:done creating header\n");
	//create file
	file = fopen(filename, "w");

    if (fwrite(&fileheader, sizeof(bmp_fileheader), 1, file) == 0)
	printf("fileheader write error");

    if (fwrite(&infoheader, sizeof(bmp_infoheader), 1, file) == 0)
	printf("infoheader write error");
    }

    imgbuf = malloc(infoheader.image_size);

    for (i = 0; i < infoheader.image_size; i += 3)
    {
	imgbuf[i] = img->b[index];
	imgbuf[i + 1] = img->g[index];
	imgbuf[i + 2] = img->r[index];
	index++;
    }
printf("DEBUG:done writing header to file\n");
    if(fwrite(imgbuf, sizeof(unsigned char), infoheader.image_size, file) == 0)
	printf("image write error");
printf("DEBUG:done writing image to file\n");
    free(filename);
    free(c_height);
    free(c_width);
    fclose(file);
printf("DEBUG:done main()\n");
time(&t);
ti = localtime(&t);
printf("DEBUG:end time %s", asctime(ti));
    return 0;
}
