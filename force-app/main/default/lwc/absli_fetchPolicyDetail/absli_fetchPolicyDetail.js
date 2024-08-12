import { LightningElement, api, track } from 'lwc';
import fetchAssets from "@salesforce/apex/ABSLI_FetchPolicyDetails.getPolicyDetailsFromDWH";


const columns = [
    { label: 'Fund Id', fieldName: 'FND_ID' },
    { label: 'Fund Name', fieldName: 'FUND_NAME'},
    { label: 'NAV', fieldName: 'NAV',type: 'currency',
    typeAttributes: { currencyCode: 'INR', step: '0.01' }},
    { label: 'Fund Value', fieldName: 'FUND_VALUE',type: 'currency',
    typeAttributes: { currencyCode: 'INR', step: '0.01' }},
    { label: 'Total Units', fieldName: 'TOT_UNITS'},
    { label: 'Policy #', fieldName: 'POL_ID'}
];

export default class Absli_fetchPolicyDetail extends LightningElement {
    @api recordId;
    @track data;
    @track responseCode;
    @track responseMsg;
    @track showError = false;
    @track showLoader = true;
    @track columns = columns;
    @track totalFundVal = '';

    connectedCallback(){
        this.invokeIntegration();

    }
    invokeIntegration(){
        console.log(this.recordId);
        this.showLoader = true;
        fetchAssets({policyId : this.recordId})
        .then((result)=>{
            debugger;
            console.log(result);
            try{
                if(result.statusCode == '200'){
                    let tempProp = JSON.parse(JSON.stringify(result.FUND_DETAILS));
                    this.data = tempProp;
                    this.totalFundVal = tempProp.BFID_RESPONSE.TOTAL_FUND_VALUE;
                    this.showLoader = false;
                }
                else{
                    this.showError = true;
                    this.responseMsg = result.message;
                    this.showLoader = false;
                }
                

            }
            catch(ex){
                this.responseMsg = 'Something went wrong ! Please contact System Administrator.';
                this.showError = true;
                this.showLoader = false;
            }
            

        })
        .catch((error)=>{
            debugger;
            console.log(error);
            this.responseMsg = 'Something went wrong ! Please contact System Administrator.';
            this.showError = true;
            this.showLoader = false;

        })
    }
}