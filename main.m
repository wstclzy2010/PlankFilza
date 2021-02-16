//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 Brandon Plank. All rights reserved.
//

#include <stdio.h>
#include "main.h"
#include "support.h"
#include <UIKit/UIKit.h>
#include "fishhook.h"
#include "BypassAntiDebugging.h"
#include "cicuta_virosa.h"
#include "rootless.h"
#include <objc/runtime.h>

@implementation PatchEntry

+ (void)load {
    disable_pt_deny_attach();
    disable_sysctl_debugger_checking();
        
    #if TESTS_BYPASS
    test_aniti_debugger();
    #endif
}

void error_popup(NSString *messgae_popup, BOOL fatal){
    if(fatal){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Fatal Error" message:messgae_popup preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                exit(0);
            }]];
            UIViewController * controller = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            [controller presentViewController:alertController animated:YES completion:NULL];
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Error" message:messgae_popup preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:NULL]];
            UIViewController * controller = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            [controller presentViewController:alertController animated:YES completion:NULL];
        });
    }
}


static void RabbitHook(Class cls, SEL selName, IMP replaced, void** orig) {
    // IGNORE ALL ORIG POINTER
    Method origMethod = class_getInstanceMethod(cls, selName);
    *orig = method_setImplementation(origMethod, replaced);
    printf("(´･ω･`) magic from orig: %p to our %p at class: %s\n", orig, replaced, [NSStringFromClass(cls) UTF8String]);
}

@class TGAlertController;

static void* (*original_TGAlertController_initAlertWithTitle)(TGAlertController *self, SEL _cmd, NSString* title, NSString* text, NSString* cancelBtn, NSString* otherBtn, id block);
static void* replaced_TGAlertController_initAlertWithTitle(TGAlertController *self, SEL _cmd, NSString* title, NSString* text, NSString* cancelBtn, NSString* otherBtn, id block) {
    if ([text containsString:@"Main binary was modified. Please reinstall Filza"]) {
        NSLog(@"Nope, not runing away");
        return original_TGAlertController_initAlertWithTitle(self, _cmd, title, @"已经绕过DRM检测，请忽略此弹窗", cancelBtn, otherBtn, NULL);
    }
    return original_TGAlertController_initAlertWithTitle(self, _cmd, title, text, cancelBtn, otherBtn, block);
}

@end

static void cancelExitAlert(void) {
    RabbitHook(objc_getClass("TGAlertController"), @selector(initAlertWithTitle:text:cancelButton:otherButtons:completion:), (IMP)&replaced_TGAlertController_initAlertWithTitle, (void**)&original_TGAlertController_initAlertWithTitle);
}

int start() {
    //Start exploitation to gain tfp0.
    Log(log_info, "==Plank Filza==");
    if(SYSTEM_VERSION_LESS_THAN(@"13.0") || SYSTEM_VERSION_GREATER_THAN(@"14.3")){
        Log(log_error, "Incorrect version");
        error_popup(@"Unsupported iOS version", true);
    } else {
        if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"14.3")){
            jailbreak(nil);
        }
    }
    return 0;
}

__attribute__((constructor))
static void initializer(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController* main =  UIApplication.sharedApplication.windows.firstObject.rootViewController;
        while (main.presentedViewController != NULL && ![main.presentedViewController isKindOfClass: [UIAlertController class]]) {
            main = main.presentedViewController;
        }
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"漏洞利用中"
                                                                       message:@"请勿离开当前页面并耐心等待两分钟..." preferredStyle:UIAlertControllerStyleAlert];
        [main presentViewController:alert animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                start();
                free(redeem_racers);
                cancelExitAlert();
                [alert dismissViewControllerAnimated:YES completion:^{ }];
                UIAlertController* alert2 = [UIAlertController alertControllerWithTitle:@"注意"
                                                                               message:@"PlankFilza由 Brandon Plank、Lakr 和 ModernPwner共同完成。 在适用法律的范围内，我们对您的设备发生的任何不良情况不承担任何责任。" preferredStyle:UIAlertControllerStyleAlert];
                [alert2 addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                    [alert2 dismissViewControllerAnimated:YES completion:^{ }];
                }]];
                [main presentViewController:alert2 animated:YES completion:nil];
            });
        }];
    });
    
}


