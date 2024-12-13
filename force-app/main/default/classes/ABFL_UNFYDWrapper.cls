public class ABFL_UNFYDWrapper {
    public String CASENUMBER;
    public String CUSTOMERNO;
    public String AUTORESPONSE;
    public String ISSMT;
    public String ISMULTIPLEINTENT;
    public String ISREGISTEREDCUSTOMER;
    public String DEDUPE;
    public String PAYTMINTERACTIONID;
    public String PRIORITY;
    public String ISSUECODE;
    public String LAN;
    public String LOB;
    public String MOODSTAMP;
    public String POTENTIALCOMPLAINT;
    public String CONFIDENCESCORE;
    public String ISTRAILMAIL;
    public String ISATTACHMENT;
    public String ISMULTIPLELAN;
    public String DISPOSITION;
    public String COMMENT;
    public String OWNERFULLNAME;
    public String INTENT;
    public Remarks REMARKS;
    public String CASE_INTEGRATION_ID;

    public class Remarks {
        public List<String> Case_type;
        public List<String> Case_Subtype;
    }

    // Method to deserialize JSON into the wrapper class
    public static ABFL_UNFYDWrapper fromJson(String jsonString) {
        return (ABFL_UNFYDWrapper) JSON.deserialize(jsonString, ABFL_UNFYDWrapper.class);
    }
    
}