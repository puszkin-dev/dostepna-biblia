#import "Gesty.h"
#import <XCTest/XCTest.h>

// Interfejs odtwarzania zaplanowanych dotknięć narzędzia XCTest, poza produktem aplikacji.
@protocol SciezkaDotyku
- (instancetype)initForTouchAtPoint:(CGPoint)point offset:(double)offset;
- (void)moveToPoint:(CGPoint)point atOffset:(double)offset;
- (void)liftUpAtOffset:(double)offset;
@end

@protocol SekwencjaDotyku
- (instancetype)initWithName:(NSString *)name interfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)addPointerEventPath:(id<SciezkaDotyku>)path;
@end

@protocol OdtwarzaczDotyku <NSObject>
- (void)synthesizeEvent:(id<SekwencjaDotyku>)record completion:(void (^)(BOOL, NSError *))completion;
@end

@interface XCUIDevice (GestyTestowe)
- (id<OdtwarzaczDotyku>)eventSynthesizer;
@end

void BibliaFlicki(CGPoint start, BOOL increment, void (^completion)(BOOL)) {
    Class recordClass = NSClassFromString(@"XCSynthesizedEventRecord");
    Class pathClass = NSClassFromString(@"XCPointerEventPath");
    XCUIDevice *device = XCUIDevice.sharedDevice;
    if (![recordClass instancesRespondToSelector:@selector(initWithName:interfaceOrientation:)] ||
        ![recordClass instancesRespondToSelector:@selector(addPointerEventPath:)] ||
        ![pathClass instancesRespondToSelector:@selector(initForTouchAtPoint:offset:)] ||
        ![pathClass instancesRespondToSelector:@selector(moveToPoint:atOffset:)] ||
        ![pathClass instancesRespondToSelector:@selector(liftUpAtOffset:)] ||
        ![device respondsToSelector:@selector(eventSynthesizer)] ||
        ![[device eventSynthesizer] respondsToSelector:@selector(synthesizeEvent:completion:)]) {
        completion(NO);
        return;
    }
    id<SekwencjaDotyku> record = [(id<SekwencjaDotyku>)[recordClass alloc]
        initWithName:@"Zmiana silnika i pierwszy flick" interfaceOrientation:UIInterfaceOrientationPortrait];
    id<SciezkaDotyku> vertical = [(id<SciezkaDotyku>)[pathClass alloc] initForTouchAtPoint:start offset:0];
    [vertical moveToPoint:CGPointMake(start.x, start.y + (increment ? -94 : 94)) atOffset:0.065];
    [vertical liftUpAtOffset:0.075];
    [record addPointerEventPath:vertical];
    // Od oderwania palca do następnego dotknięcia: 80 ms, bez synchronizacji z aplikacją.
    id<SciezkaDotyku> right = [(id<SciezkaDotyku>)[pathClass alloc] initForTouchAtPoint:start offset:0.155];
    [right moveToPoint:CGPointMake(start.x + 94, start.y) atOffset:0.220];
    [right liftUpAtOffset:0.230];
    [record addPointerEventPath:right];
    [[device eventSynthesizer] synthesizeEvent:record completion:^(BOOL result, NSError *error) {
        completion(result && error == nil);
    }];
}
