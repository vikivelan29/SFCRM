public class ASF_GraphResponse {
    
    public cls_graphs[] graphs;
    public class cls_graphs {
        public String graphId;	//1
        public cls_graphResponse graphResponse;
        public boolean isSuccessful;
    }
    public class cls_graphResponse {
        public cls_compositeResponse[] compositeResponse;
    }
    public class cls_compositeResponse {
        public cls_body[] body;
        public cls_httpHeaders httpHeaders;
        public Integer httpStatusCode;	//400
        public String referenceId;	//refCategoryConfig
    }
    public class cls_body {
        public String errorCode;	//PROCESSING_HALTED
        public String message;	//The transaction was rolled back since another operation in the same transaction failed.
    }
    public class cls_httpHeaders {
    }
    public static ASF_GraphResponse parse(String json){
        return (ASF_GraphResponse) System.JSON.deserialize(json, ASF_GraphResponse.class);
    }
}