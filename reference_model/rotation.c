/*
 *completed on 15/12/15
 *reference model
 *how to use:
 *syntax >> rotate <image> <new_image> degree direction
 *if degree not 90, 180 nor 270 it is automatically treated as 0 (through-mode)
 *degree can be CW or CCW... default is CCW
 */

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
//can't help it orz
//as much as i don't want to... boohoo (cry)
int g_height;
int g_width;
bmp_infoheader g_infoheader;
bmp_fileheader g_fileheader;

//function prototypes
image * load_image (char *filename);
image *rotate_image (image *img, int deg, int dir);
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
	char *filename = NULL;
	char *new_filename = NULL;
	char *degrees = NULL;
	char *direction = NULL;

	int deg, dir;

	image *img = NULL;
	image *new_image = NULL;

	bmp_infoheader infoheader;

	//rotate <source_image> <destination_image> <degrees>
	if (argc < 3)	
	{
		printf("%s\n", ERROR_NOT_ENOUGH_ARGUMENTS);
		return 1;
	} else 
	{
                filename = malloc(sizeof(char *));
		new_filename = malloc(sizeof(char *));
		degrees = malloc(sizeof(char *));
		direction = malloc(sizeof(char *));

		strcpy(filename, argv[1]);
		strcpy(new_filename, argv[2]);
		strcpy(degrees, argv[3]);
		strcpy(direction, argv[4]);

		/*DEBUG
		 * */
		//printf("string:%s\n",degrees);
		if (strcmp(degrees,"90") == 0)
		{
		    deg = 90;
		}
		else if (strcmp(degrees,"180") == 0)
		{
		    deg = 180;
		}
		else if (strcmp(degrees,"270") == 0)
		{
		    deg = 270;
		}
		else
		{
		    deg = 0;
		}
		//printf("integer:%d\n",deg);
		
		//printf("string:%s\n",direction);
		if (strcmp(direction,"CW") == 0)
		{
		    dir = CW;
		}
		else
		{
		    dir = CCW;
		}
		//printf("integer:%d\n",dir);

		img = load_image(filename);
		if (img == NULL)
			return 1;
		
		//print_px(img, 0);
		
		new_image = rotate_image(img, deg, dir);

		create_image(new_filename,new_image);

		//print_px(new_image, 0);
		if (img == NULL)
			return 1;
	}

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

image *rotate_image (image *img, int deg, int dir)
{
    int new_height, new_width;
    int image_size;
    int address = 0, new_address = 0, i, j;
    image * new_image;

    if (deg == 90 || deg == 270)
    {
	new_height = g_width;
	new_width = g_height;
    }
    else 
    {
	new_height = g_height;
	new_width = g_width;
    }

    g_infoheader.height = new_height;
    g_infoheader.width = new_width;

    image_size = new_height * new_width;

    new_image = malloc(sizeof(image));
    new_image->r = malloc(sizeof(unsigned char) * image_size);
    new_image->g = malloc(sizeof(unsigned char) * image_size);
    new_image->b = malloc(sizeof(unsigned char) * image_size);

    if ((deg == 90 && dir == CW)||(deg == 270 && dir == CCW))
    {
//	printf("CW 90\n");
	address = new_height - 1;
	for (i = 0; i < new_width; i++)
	{
	    new_address = i;
	    for (j = 0; j < new_height; j++)
	    {
		new_image->r[new_address] = img->r[address - j];
		new_image->g[new_address] = img->g[address - j];
		new_image->b[new_address] = img->b[address - j];
		new_address = new_address + new_width;
	    }
	    address = address + new_height;
	}
    } 
    else if (deg == 180)
    {
//	printf("180\n");
	address = (g_height * g_width) - 1;
	for (i = 0; i < image_size; i++)
	{
	    new_image->r[i] = img->r[address - i]; 
	    new_image->g[i] = img->g[address - i]; 
	    new_image->b[i] = img->b[address - i]; 
	}
    }
    else if ((deg == 90 && dir == CCW) || (deg == 270 && dir == CW)) 
    {
//	printf("CCW 90\n");
	address = new_height * new_width;
	for (i = 0; i < new_width; i++)
	{
	    address = address - new_height;
	    new_address = i;
	    for (j = 0; j < new_height; j++)
	    {
		new_image->r[new_address] = img->r[address + j];
		new_image->g[new_address] = img->g[address + j];
		new_image->b[new_address] = img->b[address + j];
		new_address = new_address + new_width;
	    }
	}
    }
    else 
    {
	printf("through mode\n");
	return img;   
    }

    return new_image;
}
