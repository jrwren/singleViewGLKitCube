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

#import "aiConfig.h"
#import "assimp.h"
#import "aiPostProcess.h"
#import "aiScene.h"


#define aisgl_min(x,y) (x<y?x:y)
#define aisgl_max(x,y) (y>x?y:x)

static void color4_to_float4(const struct aiColor4D *c, float f[4])
{
	f[0] = c->r;
	f[1] = c->g;
	f[2] = c->b;
	f[3] = c->a;
}

static void set_float4(float f[4], float a, float b, float c, float d)
{
	f[0] = a;
	f[1] = b;
	f[2] = c;
	f[3] = d;
}

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
/*
 - (void)goon {
 on=YES;
 }*/

- (void)tearDownGL{
    
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
BOOL on;

float _rotation;
float xrotation = 0;
GLuint _vertexBuffer;
GLuint _indexBuffer;

typedef struct {
    float Position[3];
    float Color[4];
} OldVertex;
const OldVertex Vertices[] = {
    {{32.585007,20.983316,13.993474}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};

//JRW: I want this, but I can't have it :(
//const Vertex Vertices[] = {
//    {{1, -1, 0},  {0,0,0}, {1, 0, 0, 1},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0,0},{0,0,0,0}},
//    {{1, 1, 0},   {0,0,0}, {0, 1, 0, 1},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0,0},{0,0,0,0}},
//    {{-1, 1, 0},  {0,0,0}, {0, 0, 1, 1},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0,0},{0,0,0,0}},
//    {{-1, -1, 0}, {0,0,0}, {0, 0, 0, 1},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0,0},{0,0,0,0}}
//};

const GLubyte Indices[] = {
    0,1,2,2,3,0
};

- (void) setupGL{
    //JRW: probably not needed.
    [EAGLContext setCurrentContext:self.context];
    
    ((GLKView*)self.view).drawableMultisample = GLKViewDrawableMultisample4X;
    
    self.effect = [[GLKBaseEffect alloc] init];
}
-(void) bindOldVertex{
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

-(void) loadModel{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dwarf" ofType:@"x"];
    const char* dwarfx = [filePath UTF8String];
    aiSetImportPropertyInteger(AI_CONFIG_PP_SBP_REMOVE, aiPrimitiveType_LINE | aiPrimitiveType_POINT );
    
    //todo: prefer the c++ interface to the C interface (says assimp) use ASSIMP::Importer::ReadFile()
    _scene = (aiScene*)  aiImportFile(dwarfx, aiProcessPreset_TargetRealtime_MaxQuality| aiProcess_Triangulate | aiProcess_FlipUVs | aiProcess_PreTransformVertices | 0);
    	
    if (_scene) {
     	textureDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
        
        [self loadTexturesWithModelPath:[filePath stringByStandardizingPath]];
        
        [self getBoundingBoxWithMinVector:&scene_min maxVectr:&scene_max];
        scene_center.x = (scene_min.x + scene_max.x) / 2.0f;
        scene_center.y = (scene_min.y + scene_max.y) / 2.0f;
        scene_center.z = (scene_min.z + scene_max.z) / 2.0f;
        
        // optional normalized scaling
        normalizedScale = scene_max.x-scene_min.x;
        normalizedScale = aisgl_max(scene_max.y - scene_min.y,normalizedScale);
        normalizedScale = aisgl_max(scene_max.z - scene_min.z,normalizedScale);
        normalizedScale = 1.f / normalizedScale;
        
        DLog(@"scene_center: %f, %f, %f", scene_center.x, scene_center.y, scene_center.z);
        DLog(@"normalizedScale: %f", normalizedScale);
        
        if(_scene->HasAnimations())
            NSLog(@"scene has animations");
        
        [self createGLResources];

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
    //[self bindOldVertex];
#define LOADMODEL 1
#if LOADMODEL
    [self loadModel];
#endif
}

-(void)drawOldVertex{
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(OldVertex), (const GLvoid *) offsetof(OldVertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(OldVertex), (const GLvoid *) offsetof(OldVertex, Color));
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

}

- (void) drawMeshes
{
    for(MeshHelper* helper in modelMeshes)
    {
        // Set up meterial state.
        //glCallList(helper.displayList);  
        glBindBuffer(GL_ARRAY_BUFFER, helper.vertexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, helper.indexBuffer);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, vPosition));
        glEnableVertexAttribArray(GLKVertexAttribColor);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, dColorDiffuse));
        
        glDrawElements(GL_TRIANGLES, helper.numIndices, GL_UNSIGNED_INT, 0);
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(_curRed, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];

    //[self drawOldVertex];
#if LOADMODEL
    [self drawMeshes];
#endif
}
float zoom = 1.0f;
-(void)update{

    if (_increasing) {
        _curRed += 0.01;
    } else {
        _curRed -= 0.01;
    }
    if (_curRed >= 1.0) {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) {
        _curRed = 0.0;
        _increasing = YES;
    }
    
    /* what I think should work: 
    float aspect = fabsf(self.view.bounds.size.height / self.view.bounds.size.width); //h/w or w/h ?
    GLKMatrix4 projectionMatrix = //GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, -10.0f, 10.0f);    
        GLKMatrix4MakeOrtho(-1, 1, - (aspect), aspect, -10, 10); //glOrtho(...)
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; //glLoadIdentity
    GLKMatrix4Translate(modelViewMatrix, 0, 0, 1.0 ); //glTranslated(0.0, 0.0, 1.0);
    GLKMatrix4Scale(modelViewMatrix, normalizedScale, normalizedScale, normalizedScale); //glScaled(normalizedScale, normalizedScale, normalizedScale);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,-scene_center.x, -scene_center.y, -scene_center.z);   //glTranslated( -scene_center.x, -scene_center.y, -scene_center.z)
    float scale = .5f;
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale,scale,scale);
    _rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0.0f, 0.25f, 1.0f); //glRotated
    self.effect.transform.modelviewMatrix = modelViewMatrix;
     */
    
//TODO: port this to ES
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glViewport(0, 0, _view.frame.size.width, _view.frame.size.height);
    
    GLfloat aspect = _view.frame.size.height/_view.frame.size.width; 
    glOrtho(-1, 1, - (aspect), aspect, -10, 10);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glTranslated(0.0, 0.0, 1.0);
    
    // Draw our GL model.    
    if(_scene)
    {
        glScaled(normalizedScale , normalizedScale, normalizedScale);
        // center the model
        glTranslated( -scene_center.x, -scene_center.y, -scene_center.z);    
        
        glScaled(1.0, 1.0, 1.0);
        
        static float i = 0;
        i+=1.5;
        glRotated(i, i, 1, 0);
        
        [self drawMeshesInContext:cgl_ctx];
    }

}
-(void)oldVertexUpdate{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.1f, 10.0f);
    //float basezoom = 0.75;
    //projectionMatrix = GLKMatrix4Scale(projectionMatrix, basezoom, basezoom, basezoom);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, zoom, zoom, zoom);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
    //GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(-10, -10, 3, scene_center.x, scene_center.y, scene_center.z, 0, 1, 0);
    //GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    //GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
    if(!self.paused)
        _rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(xrotation), 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 0, 1);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}

// Inspired by LoadAsset() & CreateAssetData() from AssimpView D3D project
- (void) createGLResources //called only from loadModel
{
    NSLog(@"yay offsetof! vPosition:%lu and dColorDiffuse:%lu", offsetof(Vertex, vPosition), offsetof(Vertex,dColorDiffuse));
    // create new mesh helpers for each mesh, will populate their data later.
    modelMeshes = [[NSMutableArray alloc] initWithCapacity:_scene->mNumMeshes];
    
    // create OpenGL buffers and populate them based on each meshes pertinant info.
    for (unsigned int i = 0; i < _scene->mNumMeshes; ++i)
    {
        NSLog(@"%u", i);
        
        // current mesh we are introspecting
        const aiMesh* mesh = _scene->mMeshes[i];
        
        // the current meshHelper we will be populating data into.
        MeshHelper* meshHelper = [[MeshHelper alloc] init];
        
        // Handle material info
        
        aiMaterial* mtl = _scene->mMaterials[mesh->mMaterialIndex];
        
        // Textures
        int texIndex = 0;
        aiString texPath;
        
        if(AI_SUCCESS == mtl->GetTexture(aiTextureType_DIFFUSE, texIndex, &texPath))
        {
            NSString* textureKey = [NSString stringWithCString:texPath.data encoding:[NSString defaultCStringEncoding]];
            //bind texture
            NSNumber* textureNumber = (NSNumber*)[textureDictionary valueForKey:textureKey];
            
            //NSLog(@"applyMaterialInContext: have texture %i", [textureNumber unsignedIntValue]); 
            meshHelper.textureID = [textureNumber unsignedIntValue];		
        }
        else
            meshHelper.textureID = 0;
        
        // Colors
        
        aiColor4D dcolor = aiColor4D(0.8f, 0.8f, 0.8f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_DIFFUSE, &dcolor))
            [meshHelper setDiffuseColor:&dcolor];
        
        aiColor4D scolor = aiColor4D(0.0f, 0.0f, 0.0f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_SPECULAR, &scolor))
            [meshHelper setSpecularColor:&scolor];
        
        aiColor4D acolor = aiColor4D(0.2f, 0.2f, 0.2f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_AMBIENT, &acolor))
            [meshHelper setAmbientColor:&acolor];
        
        aiColor4D ecolor = aiColor4D(0.0f, 0.0f, 0.0f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_EMISSIVE, &ecolor))
            [meshHelper setEmissiveColor:&ecolor];
        
        // Culling
        unsigned int max = 1;
        int two_sided;
        if((AI_SUCCESS == aiGetMaterialIntegerArray(mtl, AI_MATKEY_TWOSIDED, &two_sided, &max)) && two_sided)
            [meshHelper setTwoSided:YES];
        else
            [meshHelper setTwoSided:NO];
        
        // Create a VBO for our vertices
        
        GLuint vhandle;
        glGenBuffers(1, &vhandle);
        
        // populate vertices
        Vertex* verts = (Vertex*) //glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
            malloc(sizeof(Vertex) * mesh->mNumVertices);
        
        for (unsigned int x = 0; x < mesh->mNumVertices; ++x)
        {
            verts->vPosition = mesh->mVertices[x];
            if(0==x)
                DLog(@"Vertex! %f,%f,%f", verts->vPosition.x, verts->vPosition.y, verts->vPosition.z);
            if (NULL == mesh->mNormals)
                verts->vNormal = aiVector3D(0.0f,0.0f,0.0f);
            else
                verts->vNormal = mesh->mNormals[x];
            
            if (NULL == mesh->mTangents)
            {
                verts->vTangent = aiVector3D(0.0f,0.0f,0.0f);
                verts->vBitangent = aiVector3D(0.0f,0.0f,0.0f);
            }
            else
            {
                verts->vTangent = mesh->mTangents[x];
                verts->vBitangent = mesh->mBitangents[x];
            }
            
            if (mesh->HasVertexColors(0))
            {
                verts->dColorDiffuse = mesh->mColors[0][x];
            }
            else
                verts->dColorDiffuse = aiColor4D(1.0, 1.0, 1.0, 1.0);
            
            // This varies slightly form Assimp View, we support the 3rd texture component.
            if (mesh->HasTextureCoords(0))
                verts->vTextureUV = mesh->mTextureCoords[0][x];
            else
                verts->vTextureUV = aiVector3D(0.5f,0.5f, 0.0f);
            
            if (mesh->HasTextureCoords(1))
                verts->vTextureUV2 = mesh->mTextureCoords[1][x];
            else 
                verts->vTextureUV2 = aiVector3D(0.5f,0.5f, 0.0f);
            
            // TODO: handle Bone indices and weights
            /*          if( mesh->HasBones())
             {
             unsigned char boneIndices[4] = { 0, 0, 0, 0 };
             unsigned char boneWeights[4] = { 0, 0, 0, 0 };
             ai_assert( weightsPerVertex[x].size() <= 4);
             
             for( unsigned int a = 0; a < weightsPerVertex[x].size(); a++)
             {
             boneIndices[a] = weightsPerVertex[x][a].mVertexId;
             boneWeights[a] = (unsigned char) (weightsPerVertex[x][a].mWeight * 255.0f);
             }
             
             memcpy( verts->mBoneIndices, boneIndices, sizeof( boneIndices));
             memcpy( verts->mBoneWeights, boneWeights, sizeof( boneWeights));
             }
             else
             */ 
            {
                memset( verts->mBoneIndices, 0, sizeof( verts->mBoneIndices));
                memset( verts->mBoneWeights, 0, sizeof( verts->mBoneWeights));
            }
            
            ++verts;
        }
        //JRW: bad access :(
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * mesh->mNumVertices, verts, GL_STATIC_DRAW);
        
        //glUnmapBufferARB(GL_ARRAY_BUFFER_ARB); //invalidates verts
        
        //JRW what if I don't free?
        //free(verts);
        
        //JRW: wtf is this?
        //glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        // set the mesh vertex buffer handle to our new vertex buffer.
        meshHelper.vertexBuffer = vhandle;
        
        // Create Index Buffer
        
        // populate the index buffer.
        NSUInteger nidx;
        switch (mesh->mPrimitiveTypes)
        {
            case aiPrimitiveType_POINT:
                nidx = 1;break;
            case aiPrimitiveType_LINE:
                nidx = 2;break;
            case aiPrimitiveType_TRIANGLE:
                nidx = 3;break;
            default: assert(false);
        }   
        
        // create the index buffer
        GLuint ihandle;
        glGenBuffers(1, &ihandle);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ihandle);
        
        unsigned int* indices = (unsigned int*)  //glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY_ARB);
            malloc( sizeof(GLuint) * mesh->mNumFaces * nidx);
        // now fill the index buffer
        for (unsigned int x = 0; x < mesh->mNumFaces; ++x)
        {
            for (unsigned int a = 0; a < nidx; ++a)
            {
                //                 if(mesh->mFaces[x].mNumIndices != 3)
                //                     NSLog(@"whoa dont have 3 indices...");
                
                *indices++ = mesh->mFaces[x].mIndices[a];
            }
        }
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * mesh->mNumFaces * nidx, indices, GL_STATIC_DRAW);
        
        //JRW: i won't free... i'll leak.
        //free(indices);
        //glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        // set the mesh index buffer handle to our new index buffer.
        meshHelper.indexBuffer = ihandle;
        meshHelper.numIndices = mesh->mNumFaces * nidx;
        
        // create the normal buffer. Assimp View creates a second normal buffer. Unsure why. Using only the interleaved normals for now.
        // This is here for reference.
        
        /*          GLuint nhandle;
         glGenBuffers(1, &nhandle);
         glBindBuffer(GL_ARRAY_BUFFER, nhandle);
         glBufferData(GL_ARRAY_BUFFER, sizeof(aiVector3D)* mesh->mNumVertices, NULL, GL_STATIC_DRAW);
         
         // populate normals
         aiVector3D* normals = (aiVector3D*)glMapBuffer(GL_ARRAY_BUFFER_ARB, GL_WRITE_ONLY_ARB);
         
         for (unsigned int x = 0; x < mesh->mNumVertices; ++x)
         {
         aiVector3D vNormal = mesh->mNormals[x];
         *normals = vNormal;
         ++normals;
         }
         
         glUnmapBufferARB(GL_ARRAY_BUFFER_ARB); //invalidates verts
         glBindBuffer(GL_ARRAY_BUFFER, 0);
         
         meshHelper.normalBuffer = nhandle;
         */
        //http://gamedev.stackexchange.com/questions/11438/when-to-use-vertex-array-and-when-to-use-vbo
        
        // better help: http://openglbook.com/the-book/chapter-2-vertices-and-shapes/
        //JRW: attempt to port VAO to VBO from the above "create vao and populate it" comment
        //i can't understand what this VAO is doing since vertexes have already been bound via vhandle VBO
        // and https://developer.apple.com/library/ios/#DOCUMENTATION/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/TechniquesforWorkingwithVertexData/TechniquesforWorkingwithVertexData.html
        // Create VAO and populate it
        
        GLuint vaoHandle; 
        //glGenVertexArraysAPPLE(1, &vaoHandle);
        //glBindVertexArrayAPPLE(vaoHandle);
        glGenVertexArraysOES(1, &vaoHandle);
        glBindVertexArrayOES(vaoHandle);
        
        glBindBuffer(GL_ARRAY_BUFFER, meshHelper.vertexBuffer);
        
        //JRW: enableClientState+NormalPointer+Color+Text maybe all should become glEnableVertexAttribArray and glVertexAttribPointer calls
        glEnableClientState(GL_NORMAL_ARRAY);
        
        glNormalPointer(GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(12));
        
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(4, GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(24));
        
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(3, GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(64));
        //TODO: handle second texture
        
        // VertexPointer ought to come last, apparently this is some optimization, since if its set once, first, it gets fiddled with every time something else is update.
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(3, GL_FLOAT, sizeof(Vertex), 0);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, meshHelper.indexBuffer);
        
        //glBindVertexArrayAPPLE(0);
        glBindVertexArrayOES(0);
        
        // save the VAO handle into our mesh helper
        meshHelper.vao = vaoHandle;
        
        // Create the display list
        /*JRW: no idea how to convert this.
        GLuint list = glGenLists(1);
        
        glNewList(list, GL_COMPILE);
        
        float dc[4];
        float sc[4];
        float ac[4];
        float emc[4];        
        
        // Material colors and properties
        color4_to_float4([meshHelper diffuseColor], dc);
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, dc);
        
        color4_to_float4([meshHelper specularColor], sc);
        glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, sc);
        
        color4_to_float4([meshHelper ambientColor], ac);
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ac);
        
        color4_to_float4(meshHelper.emissiveColor, emc);
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, emc);
        
        glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
        
        // Culling
        if(meshHelper.twoSided)
            glEnable(GL_CULL_FACE);
        else 
            glDisable(GL_CULL_FACE);
        
        
        // Texture Binding
        glBindTexture(GL_TEXTURE_2D, meshHelper.textureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR); 
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); 
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); 
        
        // This binds the whole VAO, inheriting all the buffer and client state. Weeee
        glBindVertexArrayAPPLE(meshHelper.vao);        
        glDrawElements(GL_TRIANGLES, meshHelper.numIndices, GL_UNSIGNED_INT, 0);
        
        glEndList();
        
        meshHelper.displayList = list;
        */
        
      

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, vPosition));
        glEnableVertexAttribArray(GLKVertexAttribColor);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, dColorDiffuse));
        
        //meshHelper.vao = TODO
        
        //wait until post setup to draw?
        glDrawElements(GL_TRIANGLES, meshHelper.numIndices, GL_UNSIGNED_INT, 0);
        
        // Whew, done. Save all of this shit.
        [modelMeshes addObject:meshHelper];
        
        //ARC DOES THIS: [meshHelper release];
    }
}

- (void) deleteGLResources{
    
    for(MeshHelper* helper in modelMeshes)
    {
        const GLuint indexBuffer = helper.indexBuffer;
        const GLuint vertexBuffer = helper.vertexBuffer;
        const GLuint normalBuffer = helper.normalBuffer;
        const GLuint vaoHandle = helper.vao;
        //const GLuint dlist = helper.displayList;
        
        glDeleteBuffers(1, &vertexBuffer);
        glDeleteBuffers(1, &indexBuffer);
        glDeleteBuffers(1, &normalBuffer);
        //glDeleteVertexArraysAPPLE(1, &vaoHandle);
        glDeleteBuffers(1, &vaoHandle);
        
        //glDeleteLists(1, dlist);
        
        helper.indexBuffer = 0;
        helper.vertexBuffer = 0;
        helper.normalBuffer = 0;
        helper.vao = 0;
        helper.displayList = 0;
    }
    
    //ARC :) : [modelMeshes release];
    modelMeshes = nil;
}

//called only from loadModel
- (void) loadTexturesWithModelPath:(NSString*) modelPath
{    
    if (_scene->HasTextures())
    {
        NSLog(@"Support for meshes with embedded textures is not implemented");
        return;
    }
    
    /* getTexture Filenames and Numb of Textures */
	for (unsigned int m = 0; m < _scene->mNumMaterials; m++)
	{		
		int texIndex = 0;
		aiReturn texFound = AI_SUCCESS;
        
		aiString path;	// filename
        
        // TODO: handle other aiTextureTypes
		while (texFound == AI_SUCCESS)
		{
			texFound = _scene->mMaterials[m]->GetTexture(aiTextureType_DIFFUSE, texIndex, &path);
            
            NSString* texturePath = [NSString stringWithCString:path.data encoding:[NSString defaultCStringEncoding]];
            
            // add our path to the texture and the index to our texture dictionary.
            [textureDictionary setValue:[NSNumber numberWithUnsignedInt:texIndex] forKey:texturePath];
            
			texIndex++;
		}		
	}
    
    textureIds = (GLuint*) malloc(sizeof(GLuint) * [textureDictionary count]); //new GLuint[ [textureDictionary count] ];
    glGenTextures([textureDictionary count], textureIds);
    
    NSLog(@"textureDictionary: %@", textureDictionary);
    
    // create our textures, populate them, and alter our textureID value for the specific textureID we create.
    
    // so we can modify while we enumerate... 
    NSDictionary *textureCopy = [textureDictionary copy];
    
    // GCD attempt.
    //dispatch_sync(_queue, ^{
    
    int i = 0;
    
    for(NSString* texturePath in textureCopy)
    {        
        NSString* fullTexturePath = [[[modelPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[texturePath stringByStandardizingPath]] stringByStandardizingPath];
        NSLog(@"texturePath: %@", fullTexturePath);
        
        UIImage* textureImage = [[UIImage alloc] initWithContentsOfFile:fullTexturePath];
        
        if(textureImage)
        {
            /* JRW: this is hte old way:
            //NSLog(@"Have Texture Image");
            //NSBitmapImageRep* bitmap = [NSBitmapImageRep alloc];
            
            //[textureImage lockFocus];
            //[bitmap initWithFocusedViewRect:NSMakeRect(0, 0, textureImage.size.width, textureImage.size.height)];
            //[textureImage unlockFocus];
            
            glActiveTexture(GL_TEXTURE0);
            glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, textureIds[i]);
            //glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap pixelsWide]);
            //glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            
            // generate mip maps
            glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR); 
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
            
            // draw into our bitmap
            //int samplesPerPixel = [bitmap samplesPerPixel];
            
            if(![bitmap isPlanar] && (samplesPerPixel == 3 || samplesPerPixel == 4))
            {
                glTexImage2D(GL_TEXTURE_2D,
                             0,
                             //samplesPerPixel == 4 ? GL_COMPRESSED_RGBA_S3TC_DXT3_EXT : GL_COMPRESSED_RGB_S3TC_DXT1_EXT, 
                             samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                             [bitmap pixelsWide],
                             [bitmap pixelsHigh],
                             0,
                             samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                             GL_UNSIGNED_BYTE,
                             [bitmap bitmapData]);
                
            } 
            
            
            // update our dictionary to contain the proper textureID value (from out array of generated IDs)
            [textureDictionary setValue:[NSNumber numberWithUnsignedInt:textureIds[i]] forKey:texturePath];
            */
            //JRW: do this this way instead:   maybe see https://developer.apple.com/library/ios/#samplecode/GLImageProcessing/Listings/Texture_m.html#//apple_ref/doc/uid/DTS40009053-Texture_m-DontLinkElementID_13
            GLuint spriteTexture = 0;
            CGImage *image = textureImage.CGImage;
            GLsizei width = CGImageGetWidth(image);
            GLsizei height = CGImageGetHeight(image);
            CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
            
            GLubyte *spriteData = (GLubyte *)CFDataGetBytePtr(data);
            glGenTextures(1, &spriteTexture);
            
            glBindTexture(GL_TEXTURE_2D, spriteTexture);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
            
            NSLog(@"loaded texture %@ %dx%d", texturePath, width, height);
            //YAY ARC! [bitmap release];
        }
        else
        {
            [textureDictionary removeObjectForKey:texturePath];
            NSLog(@"Could not Load Texture: %@, removing reference to it.", fullTexturePath);
        }
        
        //YAY ARC! [textureImage release];
        i++;
    }       
    //});
    
    //YAY ARC! [textureCopy release];
    
}

- (void) getBoundingBoxWithMinVector:(struct aiVector3D*) min maxVectr:(struct aiVector3D*) max{
    struct aiMatrix4x4 trafo;
	aiIdentityMatrix4(&trafo);
    
	min->x = min->y = min->z =  1e10f;
	max->x = max->y = max->z = -1e10f;
    
    [self getBoundingBoxForNode:_scene->mRootNode minVector:min maxVector:max matrix:&trafo];

}
- (void) getBoundingBoxForNode:(const struct aiNode*)nd  minVector:(struct aiVector3D*) min maxVector:(struct aiVector3D*) max matrix:(struct aiMatrix4x4*) trafo
{
    struct aiMatrix4x4 prev;
	unsigned int n = 0, t;
    
	prev = *trafo;
	aiMultiplyMatrix4(trafo,&nd->mTransformation);
    
	for (; n < nd->mNumMeshes; ++n)
    {
		const struct aiMesh* mesh = _scene->mMeshes[nd->mMeshes[n]];
		for (t = 0; t < mesh->mNumVertices; ++t)
        {
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
    
	for (n = 0; n < nd->mNumChildren; ++n) 
    {
		[self getBoundingBoxForNode:nd->mChildren[n] minVector:min maxVector:max matrix:trafo];
	}
    
	*trafo = prev;
}

-(void)DISABLEDtouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.paused = !self.paused;
    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
}
- (IBAction)tap:(id)sender {
    self.paused = !self.paused;
}

float lastscale =0;
- (IBAction)pinch:(id)sender {
    UIPinchGestureRecognizer *grec = (UIPinchGestureRecognizer*)sender;
    CGFloat scale = [grec scale];
    
    float scalediff = scale-lastscale;
    lastscale = scale;
    zoom *= 1+scalediff;
    DLog(@"scale: %f, lastscale: %f, diffscale: %f, zoom: %f", scale, lastscale, scalediff, zoom);
}

- (IBAction)longPress:(id)sender {
    zoom = 1.0f;
}

//doesn't really work, they all seem to register as pinch.
- (IBAction)rotation:(id)sender {
    UIRotationGestureRecognizer *rrot = (UIRotationGestureRecognizer*)sender;
    CGFloat rotation = [rrot rotation];
    CGFloat velocity = [rrot velocity];
    DLog(@"rotation: %f, velocity: %f", rotation, velocity);
    xrotation = rotation;
}

float firstX,firstY;
CGPoint translatedPoint;
- (IBAction)pan:(id)sender {
    UIPanGestureRecognizer *pangest = (UIPanGestureRecognizer*)sender;
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        firstX = [[sender view] center].x;
        firstY = [[sender view] center].y;
    }
    
    translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY);
    
    xrotation = xrotation+ (firstX+translatedPoint.x)/200.0f;
    DLog(@"xrotation: %f", xrotation); 
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[pangest velocityInView:self.view].x);
        CGFloat finalX = translatedPoint.x + velocityX;
        CGFloat finalY = firstY;// translatedPoint.y + (.35*[(UIPanGestureRecognizer*)sender velocityInView:self.view].y);
        
        
        if(UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
            if(finalY < 0) {
                DLog(@"wtf finalY<0");
                finalY = 0;
            }
            else if(finalY > 1024) {
                finalY = 1024;
            }
        }
        else {
            if(finalX < 0) {
                //finalX = 0;
            }
            else if(finalX > 1024) {
                //finalX = 768;
            }
            if(finalY < 0) {
                finalY = 0;
            }
            else if(finalY > 768) {
                finalY = 1024;
            }
        }
    }

}


@end
    