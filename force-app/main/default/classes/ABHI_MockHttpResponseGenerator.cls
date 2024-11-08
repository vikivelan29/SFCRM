/*********************************************************
*Class        :  ABHI_MockHttpResponseGenerator
*Author       :  AC
*Created Date :  27/10/2024
*Last Modified:
*@description  :  Mock Response
*********************************************************/
@isTest
global class ABHI_MockHttpResponseGenerator implements HttpCalloutMock {
    public integer statuscode ;
    public string reponseBody ;
    
    global ABHI_MockHttpResponseGenerator(integer statuscode, string strBody) {
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