global class ASF_BulkCsvDownload_MockTest implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"query": "SELECT Id FROM Case LIMIT 10"}');
        res.setStatusCode(200);
        return res;
    }
}