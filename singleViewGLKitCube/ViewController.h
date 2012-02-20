//
//  ViewController.h
//  singleViewGLKitCube
//
//  Created by Jay R Wren on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelLoaderHelperClasses.h"

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "aiScene.h"

@interface NSArray (stuff) {
}
//JRW: first or firstObjectPassingTest ?
- (id)first: (BOOL (^)(id obj))block;
- (NSArray *)where: (BOOL (^)(id obj))block;
@end

@interface FWrapper : NSObject {
    void (^_callback)(id);
    id _sender;
}

-(FWrapper*)initWithCallback:(void(^)(id)) callback andSender:sender;
-(void)invokeTheBlock;
@end

@interface ViewController : GLKViewController //UIViewController<GLKViewDelegate>
{
    float _curRed;
    BOOL _increasing;
    aiScene* _scene;
    struct aiVector3D scene_min, scene_max, scene_center;
    double normalizedScale;    
    
    // Our array of textures.
    GLuint *textureIds;
    
    NSMutableArray* modelMeshes;   
    BOOL builtBuffers;

    NSMutableDictionary* textureDictionary;	// Array of Dicionaries that map image filenames to textureIds      

}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;


- (void) drawMeshes;
- (void) createGLResources;
- (void) deleteGLResources;

- (void) loadTexturesWithModelPath:(NSString*) modelPath;
- (void) getBoundingBoxWithMinVector:(struct aiVector3D*) min maxVectr:(struct aiVector3D*) max;
- (void) getBoundingBoxForNode:(const struct aiNode*)nd  minVector:(struct aiVector3D*) min maxVector:(struct aiVector3D*) max matrix:(struct aiMatrix4x4*) trafo;

- (IBAction)tap:(id)sender;
- (IBAction)pinch:(id)sender;
- (IBAction)longPress:(id)sender;
- (IBAction)rotation:(id)sender;
- (IBAction)pan:(id)sender;

@end
