# FTFakeTouch
Build fake touch events and send to application. So user can simulate touch by code simply.

### Example:
```
CGPoint touchPoint = CGPointMake(40, 400);
CGPoint touchPoint2 = CGPointMake(100, 400);

///Single Tap
[[FTFakeTouch sharedInstance] tapAtPoint:touchPoint];

///Drag
[[FTFakeTouch sharedInstance] dragFromPoint:touchPoint toPoint:touchPoint2 steps:10];
```

### Reference:
[KIF-framework](https://github.com/kif-framework/KIF)
