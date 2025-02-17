import { LightningElement, track,api,wire } from 'lwc';
import getGoldLoanDetails from '@salesforce/apex/ABCD_GoldLoanDetails.getGoldLoanDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
export default class AbcdGoldLoanDetailS extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track displayTable = false;
    @track displayError = false;
    @track errorMessages = '';
    @track showChildTable = false;
    @track apiName = '';
    @track payloadInfo = '';
    @track showDataTable = false; 
    @track displayError = false;
    columns;
    customerID;
    @track recordTable = []; 

    connectedCallback() {
        this.isLoading = true;
        this.displayError = false;
        console.log('recordIdgoldloan ',this.recordId);
        this.handleApi();
    }
     handleApi() {
        this.isLoading = true;
        this.displayError = false;
        getGoldLoanDetails({ 
            accountId:this.recordId
        })
        .then((result) => {
            this.isLoading = false;
            this.showDataTable = true;
            this.columnName(result);
       
            if(result.status==='Success'){
                this.columnName(result);
            }
          /*  else if (result.StatusCode ==1000 && result.serviceMessages[0].businessDesc!=null) {
                this.showDataTable = false;
                this.errorMessage = result.serviceMessages[0].businessDesc;
                this.displayError = true;

            }*/
          
           })
           .catch((error) => {
            console.log('Error----> ',JSON.stringify(error));
            this.isLoading = false;
            this.showDataTable = false;
            this.displayError = true;
            if ( error.body != null) {
                this.errorMessage =   error.body.message;
            } else if(this.apiFailure){
                this.errorMessage = this.apiFailure;
            }
            else{
                this.errorMessage = 'An unknown error occured, please contact your admin'
            }

        });
    } 
    columnName(apiResponse) {
        getColumns({ configName: 'ABCD_Gold_Loan' })
        .then(result => {
            console.log('columns----> ' + JSON.stringify(result));
            this.columns = result.map(column => ({
                label: column.MasterLabel,
                fieldName: column.Api_Name__c,
                type: column.Data_Type__c,
            }));
            this.processResponse(apiResponse);
        })
        .catch(error => {
            console.error('Error fetching columns:',  JSON.stringify(error));
        });
    }
   
    processResponse(response) {
        console.log('operationStatus ', response);
        this.recordTable = []; // Initialize as an empty array
        if (response && response.status==='Success' ) {
            const goldLoanDetails = response.goldLoanInfo.goldLoanDetails; 
            if (goldLoanDetails && goldLoanDetails.length > 0) {
                // Map the goldLoanDetails to the required structure
                this.recordTable = goldLoanDetails.map(detail => ({
                    loanAccountNumber: detail.loanAccountNumber,
                    loanStartDate: detail.loanStartDate ,
                    loanEndDate: detail.loanEndDate ,
                    tenor: detail.tenor,
                    lastDisbursedDate: detail.lastDisbursedDate,
                    nextInstallmentDate: detail.nextInstallmentDate,
                    loanType: detail.loanType ,
                    businessLOB: detail.businessLOB ,
                    disbursementDate: detail.disbursementDate ,
                    sanctionDate: detail.sanctionDate ,
                    sanctionAmount: detail.sanctionAmount,
                    rateOfInterest: detail.rateOfInterest ,
                    emi: detail.emi 
                }));
            } else {
                console.error('No gold loan  details found in the response.');
                this.error = 'No valid data available.';
            }
        } else {
            console.error('Operation status not SUCCESS or no response.');
            this.error = 'No valid response from API';
        }
    }    
    handleRefresh(){
      // this.handleApi();
    }
}