//
//  ViewController.m
//  singleViewGLKitCube
//
//  Created by Jay R Wren on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "assimp.h"
#import "aiPostProcess.h"
#import "aiScene.h"

@implementation NSArray (stuff)

- (id)first: (BOOL (^)(id obj))block{
    for (id item in self) {
        if (block(item))
            return item;
    }
    return nil;
}
-(NSArray *)where:(BOOL (^)(id))block{
    NSMutableArray *array = [[NSMutableArray alloc] init ];
    for (id item in self) {
        if (block(item)) {
            [array addObject:item];
        }
    }
    return array;
}
@end



@implementation FWrapper

-(FWrapper*)initWithCallback:(void(^)(id)) block andSender:sender {
    if (self = [super init]) {
        _callback = block;
        _sender = sender;
    }
    else{
        DLog(@"couldn't init, something bad happened");
    }
    return self;
}
-(void)invokeTheBlock {
    _callback(_sender);
}
@end

@interface UIButton (stuff) {
}
- (void)addTarget:(void (^)(id))block forControlEvents:(UIControlEvents)controlEvents;
@end
@implementation UIButton (stuff)
static const char * UIControlDDBlockActions = "unique";
- (void)addTarget:(void (^)(id))block forControlEvents:(UIControlEvents)controlEvents {
    NSMutableArray * blockActions = objc_getAssociatedObject(self, &UIControlDDBlockActions);
    if (blockActions == nil) {
        blockActions = [NSMutableArray array];
        objc_setAssociatedObject(self, &UIControlDDBlockActions, blockActions, OBJC_ASSOCIATION_RETAIN);
    }

    id del = [[FWrapper alloc] initWithCallback:block andSender:self];
    [blockActions addObject:del];
    [self addTarget:del action:@selector(invokeTheBlock) forControlEvents:controlEvents];
}
@end
@implementation ViewController

@synthesize effect = _effect;
@synthesize context = _context;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

BOOL on;

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}},
    {{1, -1, 1}, {1, 0, 1, 1}},
    {{1, 1, 1}, {1, 1, 0, 1}},
    {{-1, 1, 1}, {0, 1, 1, 1}},
    {{-1, -1, 1}, {1, 1, 1, 1}},
    
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 4,5,6,7,0
};

GLuint _vertexBuffer;
GLuint _indexBuffer;

float _rotation;

- (void) setupGL{
    //JRW: probably not needed.
    //[EAGLContext setCurrentContext:self.context];
    
    ((GLKView*)self.view).drawableMultisample = GLKViewDrawableMultisample4X;
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    
}

// the global Assimp scene object
const struct aiScene* scene = NULL;

struct aiVector3D scene_min, scene_max, scene_center;

// current rotation angle
static float angle = 0.f;

#define aisgl_min(x,y) (x<y?x:y)
#define aisgl_max(x,y) (y>x?y:x)

// ----------------------------------------------------------------------------
void reshape(int width, int height)
{
	const double aspectRatio = (float) width / height, fieldOfView = 45.0;
    
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
//	gluPerspective(fieldOfView, aspectRatio,
//                   1.0, 1000.0);  /* Znear and Zfar */
	glViewport(0, 0, width, height);
}

// ----------------------------------------------------------------------------
void get_bounding_box_for_node (const struct aiNode* nd, 
                                struct aiVector3D* min, 
                                struct aiVector3D* max, 
                                struct aiMatrix4x4* trafo
                                ){
	struct aiMatrix4x4 prev;
	unsigned int n = 0, t;
    
	prev = *trafo;
	aiMultiplyMatrix4(trafo,&nd->mTransformation);
    
	for (; n < nd->mNumMeshes; ++n) {
		const struct aiMesh* mesh = scene->mMeshes[nd->mMeshes[n]];
		for (t = 0; t < mesh->mNumVertices; ++t) {
            
			struct aiVector3D tmp = mesh->mVertices[t];
			aiTransformVecByMatrix4(&tmp,trafo);
            
			min->x = aisgl_min(min->x,tmp.x);
			min->y = aisgl_min(min->y,tmp.y);
			min->z = aisgl_min(min->z,tmp.z);
            
			max->x = aisgl_max(max->x,tmp.x);
			max->y = aisgl_max(max->y,tmp.y);
			max->z = aisgl_max(max->z,tmp.z);
		}
	}
    
	for (n = 0; n < nd->mNumChildren; ++n) {
		get_bounding_box_for_node(nd->mChildren[n],min,max,trafo);
	}
	*trafo = prev;
}

// ----------------------------------------------------------------------------
void get_bounding_box (struct aiVector3D* min, struct aiVector3D* max)
{
	struct aiMatrix4x4 trafo;
	aiIdentityMatrix4(&trafo);
    
	min->x = min->y = min->z =  1e10f;
	max->x = max->y = max->z = -1e10f;
	get_bounding_box_for_node(scene->mRootNode,min,max,&trafo);
}

// ----------------------------------------------------------------------------
void color4_to_float4(const struct aiColor4D *c, float f[4])
{
	f[0] = c->r;
	f[1] = c->g;
	f[2] = c->b;
	f[3] = c->a;
}

// ----------------------------------------------------------------------------
void set_float4(float f[4], float a, float b, float c, float d)
{
	f[0] = a;
	f[1] = b;
	f[2] = c;
	f[3] = d;
}

// ----------------------------------------------------------------------------
void apply_material(const struct aiMaterial *mtl)
{
	float c[4];
	int ret1, ret2;
	struct aiColor4D diffuse;
	struct aiColor4D specular;
	struct aiColor4D ambient;
	struct aiColor4D emission;
	float shininess, strength;
	int two_sided;
	
	uint max;
    
	set_float4(c, 0.8f, 0.8f, 0.8f, 1.0f);
	if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_DIFFUSE, &diffuse))
		color4_to_float4(&diffuse, c);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, c);
    
	set_float4(c, 0.0f, 0.0f, 0.0f, 1.0f);
	if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_SPECULAR, &specular))
		color4_to_float4(&specular, c);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, c);
    
	set_float4(c, 0.2f, 0.2f, 0.2f, 1.0f);
	if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_AMBIENT, &ambient))
		color4_to_float4(&ambient, c);
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, c);
    
	set_float4(c, 0.0f, 0.0f, 0.0f, 1.0f);
	if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_EMISSIVE, &emission))
		color4_to_float4(&emission, c);
	glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, c);
    
	max = 1;
	ret1 = aiGetMaterialFloatArray(mtl, AI_MATKEY_SHININESS, &shininess, &max);
	if(ret1 == AI_SUCCESS) {
    	max = 1;
    	ret2 = aiGetMaterialFloatArray(mtl, AI_MATKEY_SHININESS_STRENGTH, &strength, &max);
		if(ret2 == AI_SUCCESS)
			glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, shininess * strength);
        else
        	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, shininess);
    }
	else {
		glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 0.0f);
		set_float4(c, 0.0f, 0.0f, 0.0f, 0.0f);
		glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, c);
	}
    
	max = 1;
    //JRW: there is only GL_FILL in ES
    /*
	if(AI_SUCCESS == aiGetMaterialIntegerArray(mtl, AI_MATKEY_ENABLE_WIREFRAME, &wireframe, &max))
		fill_mode = wireframe ? GL_LINE : GL_FILL;
	else
		fill_mode = GL_FILL;
	glPolygonMode(GL_FRONT_AND_BACK, fill_mode);
    */
	max = 1;
	if((AI_SUCCESS == aiGetMaterialIntegerArray(mtl, AI_MATKEY_TWOSIDED, &two_sided, &max)) && two_sided)
		glDisable(GL_CULL_FACE);
	else 
		glEnable(GL_CULL_FACE);
     
}

// see http://www.lighthouse3d.com/cg-topics/code-samples/importing-3d-models-with-assimp/

// ----------------------------------------------------------------------------
void recursive_render (const struct aiScene *sc, const struct aiNode* nd)
{
	unsigned int n = 0, t;
	struct aiMatrix4x4 m = nd->mTransformation;
    
	// update transform
	aiTransposeMatrix4(&m);
	glPushMatrix();
	glMultMatrixf((float*)&m);
    
	// draw all meshes assigned to this node
	for (; n < nd->mNumMeshes; ++n) {
		const struct aiMesh* mesh = scene->mMeshes[nd->mMeshes[n]];
        
		apply_material(sc->mMaterials[mesh->mMaterialIndex]);
        
		if(mesh->mNormals == NULL) {
			glDisable(GL_LIGHTING);
		} else {
			glEnable(GL_LIGHTING);
		}
        NSMutableData *indices = [[NSMutableData alloc] init];
		for (unsigned int t = 0; t < mesh->mNumFaces; ++t) {
			const struct aiFace* face = &mesh->mFaces[t];
            glVertexPointer(3, GL_FLOAT, 0, mesh->mVertices);
            glNormalPointer(GL_FLOAT, 0, mesh->mNormals);
            glTexCoordPointer(3, GL_FLOAT, 0, &mesh->mTextureCoords[0][0]);
            //glVertexAttribPointer(uniformVariable[0], 3, GL_FLOAT, GL_FALSE, 0, mesh->mTangents);
            //glVertexAttribPointer(uniformVariable[1], 3, GL_FLOAT, GL_FALSE, 0, mesh->mBitangents);
            
            
                //indices.push_back(face->mIndices[0]);
                //indices.push_back(face->mIndices[1]);
                //indices.push_back(face->mIndices[2]);
                [indices appendBytes:&(face->mIndices[0]) length:sizeof(int)];
                [indices appendBytes:&(face->mIndices[1]) length:sizeof(int)];
                [indices appendBytes:&(face->mIndices[2]) length:sizeof(int)];
            
            //glDrawElements(GL_TRIANGLES, indices.size(), GL_UNSIGNED_INT, &indices[0]);
            glDrawElements(GL_TRIANGLES, indices.length, GL_UNSIGNED_INT, indices.bytes);
            //indices.clear();
            indices = [[NSMutableData alloc] init]; //jrw note: this is weird, will this leak or will ARC release correctly?
		}
        
	}
    
	// draw all children
	for (n = 0; n < nd->mNumChildren; ++n) {
		recursive_render(sc, nd->mChildren[n]);
	}
    
	glPopMatrix();
}


-(void) loadModel{
    const char* dwarfx;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dwarf" ofType:@"x"];
    dwarfx = [filePath UTF8String];
    //todo: prefer the c++ interface to the C interface (says assimp) use ASSIMP::Importer::ReadFile()
    scene = aiImportFile(dwarfx, aiProcessPreset_TargetRealtime_MaxQuality);
    	
    if (scene) {
     	get_bounding_box(&scene_min,&scene_max);
     	scene_center.x = (scene_min.x + scene_max.x) / 2.0f;
     	scene_center.y = (scene_min.y + scene_max.y) / 2.0f;
     	scene_center.z = (scene_min.z + scene_max.z) / 2.0f;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _increasing = YES;
    _curRed = 0.0;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *glkview = /*(GLKView*)[self.view.subviews //where subview class is GLKView
     first:^BOOL(id obj) {
         return [obj isKindOfClass:[GLKView class]];
     }];
    NSAssert(nil!= glkview, @"oh no!");*/
    (GLKView*)self.view;
    glkview.context = self.context;
    
    /*glkview.delegate = self;
    glkview.enableSetNeedsDisplay = NO;
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    */
    
    NSArray * buttons = 
    [self.view.subviews where:^BOOL(id obj) {
        return [obj isKindOfClass:[UIButton class]];
    }];
    if ([buttons count] >0) {
        UIButton *go = [buttons objectAtIndex:0];
        UIButton *stop = [buttons objectAtIndex:1];
        //go addTarget:<#(id)#> action:<#(SEL)#> forControlEvents:<#(UIControlEvents)#>
        [go addTarget:^(id sender){ self.paused=YES; } forControlEvents:UIControlEventTouchUpInside];
        [stop addTarget:^(id sender){ self.paused=NO; } forControlEvents:UIControlEventTouchUpInside];
    }
    //[go addTarget:self action:@selector(goon) forControlEvents:UIControlEventTouchUpInside];
    [self setupGL];
    [self loadModel];
}
- (void)goon {
    on=YES;
}

- (void)tearDownGL{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    self.effect = nil;
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self tearDownGL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(_curRed, 0.0, 0.0, _curRed);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
        

    //glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

    
    DLog(@"zomg!");

}
-(void)update{
    DLog(@"wtf!");
    if (_increasing) {
        _curRed += 0.01;
        Vertices[0].Position[2] +=.11;
        Vertices[0].Color[0] -= .01;
    } else {
        _curRed -= 0.01;
        Vertices[0].Position[2] -= .11;
        Vertices[0].Color[1] += .01;
    }
    if (_curRed >= 1.0) {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) {
        _curRed = 0.0;
        _increasing = YES;
    }
    
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);   
    _rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 1, 1);
    self.effect.transform.modelviewMatrix = modelViewMatrix;

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    recursive_render(scene, scene->mRootNode);
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.paused = !self.paused;
    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
}
@end
    