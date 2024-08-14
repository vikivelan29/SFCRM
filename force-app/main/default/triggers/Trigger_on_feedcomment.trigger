trigger Trigger_on_feedcomment on FeedComment (before delete) {
      If(Trigger.Isbefore && Trigger.Isdelete){
        FeedcommentHandler.restrictdeletionofcomment(Trigger.old);
    }
}