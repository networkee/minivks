%hook MessagesModel
-(void)markMessageRead:(id)read {
    return;
}
%end

%hook VKAPI
+(id)requestForTypingInDialog:(id)dialog success:(id)success failure:(id)failure {
    return nil;
}
%end

%hook StoriesModel
- (void)markStoryAsSeen:(id)arg1 fromSource:(id)arg2 {
    return;
}
%end
