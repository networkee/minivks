%hook ExternalAdsStatsManager
- (void)registerAdData:(id)arg1 event:(int)arg2 { return; }
- (void)registerStats:(id)arg1 { return; }
- (void)processUrl:(id)arg1 { return; }
%end

%hook VKCountersUpdater
- (void)touch { return; }
- (void)update { return; }
%end

%hook StatsManager
- (void)registerEvent:(id)arg1 batch:(BOOL)arg2 { return; }
%end

%hook MRDefaultTracker
- (void)subscribeSystemEvents { return; }
- (void)sendEventsByTimer { return; }
- (void)stopTimer { return; }
- (void)startTimer:(double)arg1 { return; }
- (void)trackLaunch { return; }
- (void)onApplicationStop:(id)arg1 { return; }
- (void)onApplicationStart:(id)arg1 { return; }
- (void)trackLevelAchievedWithLevel:(id)arg1 eventParams:(id)arg2 { return; }
- (void)trackLevelAchievedWithLevel:(id)arg1 { return; }
- (void)trackLevelAchieved { return; }
- (void)trackPurchaseWithProduct:(id)arg1 transaction:(id)arg2 eventParams:(id)arg3 { return; }
- (void)trackPurchaseWithProduct:(id)arg1 transaction:(id)arg2 { return; }
- (void)trackRegistrationEventWithParams:(id)arg1 { return; }
- (void)trackRegistrationEvent { return; }
- (void)trackInviteEventWithParams:(id)arg1 { return; }
- (void)trackInviteEvent { return; }
- (void)trackLoginEventWithParams:(id)arg1 { return; }
- (void)trackLoginEvent { return; }
- (void)trackEventWithName:(id)arg1 eventParams:(id)arg2 { return; }
- (void)trackEventWithName:(id)arg1 { return; }
- (void)setup { return; }
- (BOOL) isEnabled { return FALSE; }
%end

%hook MRMyTracker
+ (void)removeTracker { return; }
+ (void)trackLevelAchievedWithLevel:(id)arg1 eventParams:(id)arg2 { return; }
+ (void)trackLevelAchievedWithLevel:(id)arg1 { return; }
+ (void)trackLevelAchieved { return; }
+ (void)trackPurchaseWithProduct:(id)arg1 transaction:(id)arg2 eventParams:(id)arg3 { return; }
+ (void)trackPurchaseWithProduct:(id)arg1 transaction:(id)arg2 { return; }
+ (void)trackRegistrationEventWithParams:(id)arg1 { return; }
+ (void)trackRegistrationEvent { return; }
+ (void)trackInviteEventWithParams:(id)arg1 { return; }
+ (void)trackInviteEvent { return; }
+ (void)trackLoginEventWithParams:(id)arg1 { return; }
+ (void)trackLoginEvent { return; }
+ (void)trackEventWithName:(id)arg1 eventParams:(id)arg2 { return; }
+ (void)trackEventWithName:(id)arg1 { return; }
+ (void)setupTracker { return; }
+ (void)createTracker:(id)arg1 { return; }
+ (BOOL)isEnabled { return FALSE; }
%end
