#import <UIKit/UIKit.h>

/// Wysyła dwa zaplanowane gesty jako jedną sekwencję; wyłącznie dla procesu testów.
void BibliaFlicki(CGPoint start, BOOL increment, void (^_Nonnull completion)(BOOL));
