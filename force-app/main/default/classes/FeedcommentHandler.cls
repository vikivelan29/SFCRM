public class FeedcommentHandler {
        Public static void restrictdeletionofcomment(List<feedcomment>feeditms){
        for(feedcomment fd:feeditms){
            fd.adderror('Deletion is not allowed');
        }
    }
}