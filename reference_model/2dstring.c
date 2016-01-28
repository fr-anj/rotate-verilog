//Completed on: 2015-12-07
//simulates image rotation 
//by displaying strings
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char * create_image (int h, int w);
void print_image (char * image, int h, int w);
void rotate_image(char * image, int h, int w);

int main ()
{
	int h, w;
	char *image;
	
	printf ("h:");
	scanf("%d",&h);
	printf("w:");
	scanf("%d",&w);

	image = create_image(h,w);
	if (image == NULL)
		return 1;

	printf("input image:\n");
	print_image(image,h,w);
	
	rotate_image(image,h,w);
	
	return 0;
}

char * create_image (int h, int w)
{
	int i, j;
	char * image;

	//allocate memory for sample image
	image = calloc(h*w,sizeof(char));

	for (i = 0; i < (h*w); i++)
	{
	
		switch (rand()%h)
		{
			case 0: image[i]='0';break;
			case 1: image[i]='1';break;
			case 2: image[i]='2';break;
			case 3: image[i]='3';break;
			default: image[i]='=';break;
		}		
	}

	return image;
}

void print_image(char * image,int h, int w)
{
	int i, j; 

	for (i = 0; i < (h*w); i++)
	{
	
		printf("%c ",image[i]);
		if (i%w==w-1 && i > 0)
			printf("\n");
	}
}

void rotate_image(char * image, int h, int w)
{
	char *new_image;
	int new_h, new_w;
	int i,j,address,new_address;

	new_h = w;
	new_w = h;
	
	printf("output image:\n");
	
	new_image = calloc(new_h * new_w,sizeof(char));
	if (new_image == NULL)
		printf("ERROR creating output image");

	printf("90:\n");

	address = new_h * new_w;
	for(i = 0; i < new_w; i++)
	{
		address = address - new_h;
		new_address = i;
		for (j = 0; j < new_h; j++)
		{
			new_image[new_address] = image[address + j];
			new_address = new_address + new_w;
		}
	}

	print_image(new_image, new_h, new_w);

	printf("180:\n");

	address = (h * w) - 1;
	for (i = 0; i < (h * w); i ++)
	{
		new_image[i] = image[address - i];
	}

	print_image(new_image, h, w);

	printf("270:\n");

	address = new_h - 1; 
	for (i = 0; i < new_w; i++)
	{
		new_address = i;
		for (j = 0; j < new_h; j++ )
		{
			new_image[new_address] = image[address - j];
			new_address = new_address + new_w;
		}
		address = address + new_h;
	}

	print_image(new_image, new_h, new_w);
}
