@isTest
global class RNWL_MockHttpResponseGenerator implements HttpCalloutMock {
    
    public integer statuscode ;
    public string reponseBody ;
    
    global RNWL_MockHttpResponseGenerator(integer statuscode, string strBody) {
        this.statuscode = statuscode;
        this.reponseBody = strBody; 
    }
    
    global HTTPResponse respond(HTTPRequest req) { 
        // Create a fake response v1
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(reponseBody);
        res.setStatusCode(statuscode);
        return res;
    }
}