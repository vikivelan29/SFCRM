public class ABHI_CreateHealthIntentRequestWrapper {
	 public class ActivityDetail {
        public String DoYouTrackThese;
        public String FrequencyInMonth;
        public String HowDoYouTrackYourActivity;
        public String WhatActivitiesCurrentlyDoing;
    }

    public class CategoryDetail {
        public List<ActivityDetail> ActivityDetails;
        public String Category;
    }

    public class RequestBody {
        public String ActiveOnSocialMedia;
        public List<CategoryDetail> CategoryDetails;
        public String HealthReturn;
        public String MemberId;
        public String PreferredCommunicationMode;
        public String PreferredLanguage;
        public String SocialMediaId;
        public String Source;
        public String WaitingPeriodAndExclusive;
        public String WhichPhone;
    }

    public class SuccessResponse {
        public String memberId;
        public String StatusCode;
        public String StatusMessage;
        public String StatusRemarks;
    }

    public class FailureResponse {
        public String StatusCode;
        public String StatusMessage;
        public String StatusRemarks;
    }
}