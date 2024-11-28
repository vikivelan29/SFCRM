@isTest
global class ASF_ListViewAPIMock implements HttpCalloutMock{
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"query":"Select Id from Case"}');
        res.setStatusCode(200);
        return res;
    }
}