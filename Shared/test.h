
class Test {
public:
	Test();
	virtual ~Test();
	NSString* testC();
	NSString* testAsm();
	NSString* testNeon();
private:
	unsigned char*	image;
	int				width;
	int				height;

	unsigned int getTime();
};
