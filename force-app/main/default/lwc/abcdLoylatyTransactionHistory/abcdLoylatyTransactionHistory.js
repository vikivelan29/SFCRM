import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import getTrasanctionDetails from '@salesforce/apex/ABCD_Loyalty_Rewards.getRoyaltyRewardsDetails';

export default class AbcdLoylatyTransactionHistory extends LightningElement {
    @api mobileNumber;
    @track customerID;  
    @track selectedOption = 'last5'; 
    @track fromDate = '';
    @track toDate = '';
    @track showDateFields = false;
    @track isModalOpen = false;
    @track transactionDetails = [];
    showTransactionTable = false;
    @track showDataTable = false;
    @track displayError = false;
    @track currentPage = 1;
    @track pageSize = 5;
    @api clientid;
    @api emailId; 
    @api recordId;
    startDate;
    endDate;
    columns;
    @track recordTable = []; 


    get options() {
        return [
            { label: 'Last 5 transactions', value: 'last5' },
            { label: 'Date Filter', value: 'custom' }
        ];
    }
   
  

    handleOptionChange(event) {
        this.selectedOption = event.detail.value;
        this.showDateFields = this.selectedOption === 'custom';
        if (!this.showDateFields) {
            this.fromDate = '';
            this.toDate = '';
        }
    }
    
    handleDateChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        this.validateDates();
    }
    

    validateDates() {
        const today = new Date().toISOString().split('T')[0]; 
        const startDateObj = new Date(this.startDate);  
        const endDateObj = new Date(this.endDate); 
    
        if (this.startDate && this.startDate > today) {
            this.showToast('Error', 'From Date cannot be greater than today.', 'error');
            this.startDate = '';
        }
    
        else if (this.endDate && this.endDate < this.startDate) {
            this.showToast('Error', 'To Date cannot be earlier than From Date.', 'error');
            this.endDate = '';
        }
    
       else if (this.endDate && endDateObj > new Date()) {
            this.showToast('Error', 'To Date cannot be a future date.', 'error');
            this.endDate = '';
        }
    
      else  if (this.startDate && this.endDate) {
            const timeDifference = endDateObj - startDateObj; 
            const dayDifference = timeDifference / (1000 * 3600 * 24); 
            if (dayDifference > 30) {
                this.showToast('Error', 'The difference between From Date and To Date cannot be more than 30 days.', 'error');
                this.endDate = ''; // Resetting  the end date
            }
        }
    }
    
     /* validateDates() {
        if (this.startDate && this.endDate) {
            const start = new Date(this.startDate);
            const end = new Date(this.endDate);

            if (end < start) {
                this.displayErrorSearch = true;
                this.errorMessageSearch= 'End Date cannot be earlier than Start Date.';
            } else {
                this.displayErrorSearch = false;
            }
        } else {
            this.displayErrorSearch = false; // Hide error if one of the dates is missing
        }
    }
    */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
    get isButtonVisible() {
        return this.selectedOption === 'last5' || (this.startDate && this.endDate);
    }
    
    handleClear() {
        this.selectedOption = 'last5';
        this.showDateFields = false;
        this.fromDate = '';
        this.toDate = '';
        this.transactionDetails = [];
        this.showTransactionTable = false;
        this.showDataTable = false;
        this.currentPage = 1;
        this.displayError = false;
    }

    @api openModal(recordId) {
        if (recordId) {
            this.recordId = recordId;
            this.isModalOpen = true;
        }
    }
    
    closeModal() {
        this.isModalOpen = false;
    }

    
    async getTransaction() {
        this.displayError = false;
        const result = await getTrasanctionDetails({
            accountId:this.recordId,
            fromDate:  this.startDate,
            toDate:  this.endDate
        })
        .then((result) => {
            this.isLoading = false;
            this.showDataTable = true;
           // this.columnName(result);
       
            if(result.StatusCode=== 400){
                this.columnName(result);
            }
            else if (result.StatusCode != 400 ) {
                this.showDataTable = false;
                this.errorMessage = result.message;
                this.displayError = true;

            }
          
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
   

    get totalPages() {
        return Math.ceil(this.transactionDetails.length / this.pageSize);
    }
    columnName(apiResponse) {
        getColumns({ configName: 'ABCD_Loyalty_Rewards' })
        .then(result => {
           // console.log('columns----> ' + JSON.stringify(result));
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

    get paginatedTransactions() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.transactionDetails.slice(start, start + this.pageSize);
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    get bDisablePrevious() {
        return this.currentPage == 1;
    }
    get bDisableNext() {
        return this.currentPage == this.totalPages;
    }
    processResponse(response) {
        //console.log('operationStatus ', response);
        this.recordTable = [];  
        
        if (response && response.StatusCode === 400) {

            const responseData = response.ReturnData;  
            console.log('operationStatusss ', responseData);

                if (responseData && responseData.length > 0) {
                this.recordTable = responseData.map(detail => ({
                    CustomerID: detail.CustomerID,
                    LR_coins_latest_accrual_date: detail.LR_coins_latest_accrual_date,
                    LR_coins_latest_earned_coins: detail.LR_coins_latest_earned_coins,
                    LR_coins_latest_transaction_amount: detail.LR_coins_latest_transaction_amount,
                    OrderDescription: detail.OrderDescription,
                    Productname: detail.Productname,
                    RedemptionRequestID: detail.RedemptionRequestID,
                    RequestDate: detail.RequestDate,
                    cash_purchase: detail.cash_purchase,
                    channel: detail.channel,
                    offer_id: detail.offer_id,
                    points: detail.points,
                    points_redeemed: detail.points_redeemed,
                    source: detail.source,
                    total_amount: detail.total_amount,
                    transaction_amount: detail.transaction_amount,
                    transaction_date: detail.transaction_date,
                    transaction_type: detail.transaction_type,
                    unique_customer_id: detail.unique_customer_id
                }));
            } else {
                console.error('No data found in the response.');
                this.error = 'No valid data available.';
            }
        } else {
            console.error('Status code not 400 or no response.');
            this.error = 'No valid response from API';
        }
    }    
    handleStartDateChange(event) {
        this.startDate = event.target.value;
        console.log('startdate ',this.startDate);
        this.validateDates();
    }
    

    // Event handler for the end date change
    handleEndDateChange(event) {
        this.endDate = event.target.value;
        console.log('startdate ',this.endDate);
        this.validateDates();

    }
}