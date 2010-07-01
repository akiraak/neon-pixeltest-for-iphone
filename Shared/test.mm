#import <sys/time.h>
#import "test.h"

//--------------------------------
#define IMAGE_SIZE_W		(1024)
#define IMAGE_SIZE_H		(768)
#define CHECK_COLOR			(0xFF)
#define LOOP_COUNT			(100)
#define ELEMENT_OF_PIXEL	(4)

//--------------------------------
Test::Test():
image(NULL),
width(IMAGE_SIZE_W),
height(IMAGE_SIZE_H)
{
	int startTime = getTime();
	image = (unsigned char*)malloc(IMAGE_SIZE_W*IMAGE_SIZE_H*ELEMENT_OF_PIXEL);
	for(int i = 0; i < IMAGE_SIZE_W*IMAGE_SIZE_H*ELEMENT_OF_PIXEL; i++){
		image[i] = rand() % 256;
	}
	int endTime = getTime();
	NSLog(@"time: %d msec", endTime - startTime);
}
//--------------------------------
Test::~Test(){
	if(image){
		free(image);
	}
}
//--------------------------------
NSString* Test::testC(){
	int pixelCount = width * height;
	int hitCount = 0;
	int startTime = getTime();
	for(int i = 0; i < LOOP_COUNT; i++){
		unsigned char* imageWork = image;
		for(int j = 0; j < pixelCount; j++){
			int color = imageWork[0]+imageWork[1]+imageWork[2];
			if(color < CHECK_COLOR){
				hitCount++;
			}
			imageWork += ELEMENT_OF_PIXEL;
		}
	}
	int endTime = getTime();
	NSString* string = [NSString stringWithFormat:@"Pixcel: %d\nHit Pixel: %d\nTime: %d msec\n", pixelCount * LOOP_COUNT, hitCount, endTime-startTime];
	return string;
}
//--------------------------------
NSString* Test::testAsm(){
	int pixelCount = width * height;
	int hitCount = 0;
	int checkColor = CHECK_COLOR;
	int startTime = getTime();
	for(int i = 0; i < LOOP_COUNT; i++){
		__asm__ volatile (
						  "mov	r0, #0 \n\t"

						  // ループ開始
						  "1: \n\t"
						  "add	r0, r0, #1 \n\t"
						  
						  "ldrb	r3, [%[image]] \n\t"
						  "ldrb	r2, [%[image], #1] \n\t"
						  "add	r2, r2, r3  \n\t"
						  
						  "ldrb	r3, [%[image], #2] \n\t"
						  "add	r2, r2, r3  \n\t"
						  "add	%[image], %[image], #4  \n\t"

						  // 色判定とカウント
						  "cmp	r2, %[checkColor] \n\t"
						  "addlt %[hitCount], %[hitCount], #1 \n\t"

						  // 「ループ開始」へ戻る
						  "cmp	r0, %[pixelCount] \n\t"
						  "bne	1b \n\t"

						  : [hitCount] "+r" (hitCount)
						  : [pixelCount] "r" (pixelCount), [image] "r" (image), [checkColor] "r" (checkColor)
						  : "r0", "r1", "r2", "r3", "cc", "memory"
						  );
	}
	int endTime = getTime();
	NSString* string = [NSString stringWithFormat:@"Pixcel: %d\nHit Pixel: %d\nTime: %d msec\n", pixelCount * LOOP_COUNT, hitCount, endTime-startTime];
	return string;
}
//--------------------------------
NSString* Test::testNeon(){
	int pixelCount = 4096;
	int innerLoop = ((width*height)/pixelCount);
	int totalHitCount = 0;
	unsigned int checkColor =
		CHECK_COLOR << 24 |
		CHECK_COLOR << 16 |
		CHECK_COLOR << 8 |
		CHECK_COLOR << 0;
	int startTime = getTime();
	unsigned int addMask = 0x01010101;
	for(int i = 0; i < LOOP_COUNT; i++){
		unsigned char* _image = image;
		for(int j = 0; j < innerLoop; j++){
			int hitCount = 0;
			__asm__ volatile (
							  // 初期化
							  "mov	r0, #0 \n\t" // 0クリア用
							  "mov	r1, #0 \n\t" // 処理済みピクセルのカウンタ
							  "vmov.u32 d8, r0, r0 \n\t"
							  "vmov.u32 d9, r0, r0 \n\t"
							  "vmov.u32 d10, %[checkColor], %[checkColor] \n\t"
							  "vmov.u32 d11, %[checkColor], %[checkColor] \n\t"
							  "vmov.u32 d12, %[addMask], %[addMask] \n\t"
							  "vmov.u32 d13, %[addMask], %[addMask] \n\t"
							  
							  // ループ開始
							  "1: \n\t"
							  "add	r1, r1, #16 \n\t"

							  // データの読込と色の加算
							  "add		r2, %[image], #32 \n\t"
							  "vld4.8	{d0, d2, d4, d6}, [%[image]] \n\t"
							  "vld4.8	{d1, d3, d5, d7}, [r2] \n\t"
							  "vqadd.u8	q0, q1 \n\t"
							  "vqadd.u8	q0, q2 \n\t"
							  
							  // 色の判定とカウント
							  "vclt.u8 q1, q0, q5 \n\t"
							  "vand q1, q6 \n\t"
							  "vadd.u8 q4, q4, q1 \n\t"
							  
							  // データのアドレスを進める
							  "add	%[image], #64 \n\t"

							  // 「ループ開始」へ
							  "cmp	r1, %[pixelCount] \n\t"
							  "bcc	1b \n\t"

							  // 色数の合計
							  "mov	r0, #0 \n\t"
							  "vmov.u32	r1, d8[0] \n\t"
							  "2: \n\t"
							  "and		r2, r1, #0xFF \n\t"
							  "add		%[hitCount], r2 \n\t"
							  "lsr		r1, #8 \n\t"
							  "add		r0, #1 \n\t"
							  "cmp		r0, #4 \n\t"
							  "bne		2b \n\t"

							  "mov	r0, #0 \n\t"
							  "vmov.u32	r1, d8[1] \n\t"
							  "3: \n\t"
							  "and		r2, r1, #0xFF \n\t"
							  "add		%[hitCount], r2 \n\t"
							  "lsr		r1, #8 \n\t"
							  "add		r0, #1 \n\t"
							  "cmp		r0, #4 \n\t"
							  "bne		3b \n\t"
							  
							  "mov	r0, #0 \n\t"
							  "vmov.u32	r1, d9[0] \n\t"
							  "4: \n\t"
							  "and		r2, r1, #0xFF \n\t"
							  "add		%[hitCount], r2 \n\t"
							  "lsr		r1, #8 \n\t"
							  "add		r0, #1 \n\t"
							  "cmp		r0, #4 \n\t"
							  "bne		4b \n\t"
							  
							  "mov	r0, #0 \n\t"
							  "vmov.u32	r1, d9[1] \n\t"
							  "5: \n\t"
							  "and		r2, r1, #0xFF \n\t"
							  "add		%[hitCount], r2 \n\t"
							  "lsr		r1, #8 \n\t"
							  "add		r0, #1 \n\t"
							  "cmp		r0, #4 \n\t"
							  "bne		5b \n\t"
							  
							  : [hitCount] "+r" (hitCount)
							  : [pixelCount] "r" (pixelCount), [image] "r" (_image), [checkColor] "r" (checkColor), [addMask] "r" (addMask)
							  : "r0", "r1", "r2", "q0", "q1", "q2", "q3", "q4", "cc", "memory"
							  );
			
			totalHitCount += hitCount;
		}
	}
	int endTime = getTime();
	NSString* string = [NSString stringWithFormat:@"Pixcel: %d\nHit Pixel: %d\nTime: %d msec\n", pixelCount * LOOP_COUNT, totalHitCount, endTime-startTime];
	return string;
}
//--------------------------------
#if 0
// データ読込にARM命令を使用して
// 計算にNEONを使用したプログラム
// 処理が遅いけど参考のために残しておく
NSString* Test::testNeon(){
	int pixelCount = width * height;
	int totalHitCount = 0;
	int checkColor = CHECK_COLOR;
	int startTime = getTime();
	unsigned int a = 0;
	for(int i = 0; i < LOOP_COUNT; i++){
		int hitCount = 0;
		__asm__ volatile (
						  // 初期化
						  "mov	r0, #0 \n\t"
						  "vmov.u32 d8, r0, r0 \n\t"
						  "vmov.u32 d9, r0, r0 \n\t"
						  "vmov.u32 d6, %[checkColor], %[checkColor] \n\t"
						  "vmov.u32 d7, %[checkColor], %[checkColor] \n\t"
						  
						  // ループ開始
						  "1: \n\t"
						  "add	r0, r0, #4 \n\t"
						  
						  "ldrb r1, [%[image]] \n\t"  
						  "ldrb r2, [%[image], #1] \n\t"  
						  "ldrb r3, [%[image], #2] \n\t"  
						  
						  "ldrb r4, [%[image], #4] \n\t"  
						  "ldrb r5, [%[image], #5] \n\t"  
						  "ldrb r6, [%[image], #6] \n\t"  
						  
						  "vmov d0, r1, r4 \n\t"
						  "vmov d2, r2, r5 \n\t"
						  "vmov d4, r3, r6 \n\t"
						  
						  "ldrb r1, [%[image], #8] \n\t"  
						  "ldrb r2, [%[image], #9] \n\t"  
						  "ldrb r3, [%[image], #10] \n\t"  
						  
						  "ldrb r4, [%[image], #12] \n\t"  
						  "ldrb r5, [%[image], #13] \n\t"  
						  "ldrb r6, [%[image], #14] \n\t"  
						  
						  "vmov d1, r1, r4 \n\t"
						  "vmov d3, r2, r5 \n\t"
						  "vmov d5, r3, r6 \n\t"
						  
						  "add %[image], %[image], #16 \n\t"  
						  
						  "vadd.s32	q0, q0, q1 \n\t"
						  "vadd.s32	q0, q0, q2 \n\t"
						  
						  // カウント
						  "vclt.s32 q1, q0, q3 \n\t"
						  "vsub.s32 q4, q4, q1 \n\t"
						  
						  // 「ループ開始」へ
						  "cmp	r0, %[pixelCount] \n\t"
						  "bcc	1b \n\t"
						  
						  // 色判定とカウント
						  "vmov.s32 %[hitCount], d8[0] \n\t"
						  "vmov.s32 r0, d8[1] \n\t"
						  "vmov.s32 r1, d9[0] \n\t"
						  "vmov.s32 r2, d9[1] \n\t"
						  "add %[hitCount], r0 \n\t"
						  "add %[hitCount], r1 \n\t"
						  "add %[hitCount], r2 \n\t"
						  
						  : [a] "+r" (a), [hitCount] "+r" (hitCount)
						  : [pixelCount] "r" (pixelCount), [image] "r" (image), [checkColor] "r" (checkColor)
						  : "r0", "r1", "r2", "r3", "r4", "r5", "r6", "q0", "q1", "q2", "q3", "q4", "cc", "memory"
						  );
		totalHitCount += hitCount;
	}
	int endTime = getTime();
	NSString* string = [NSString stringWithFormat:@"Pixcel: %d\nHit Pixel: %d\nTime: %d msec\n", pixelCount * LOOP_COUNT, totalHitCount, endTime-startTime];
	return string;
}
#endif
//--------------------------------
unsigned int Test::getTime(){
	struct timeval t;
	gettimeofday(&t, NULL);
	return (t.tv_sec * 1000) + (t.tv_usec / 1000);
}
