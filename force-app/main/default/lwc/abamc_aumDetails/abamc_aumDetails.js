import { LightningElement, api, track } from 'lwc';
import fetchAUMDetails from '@salesforce/apex/ABSLAMC_AUMAPIDetailsController.fetchAUMDetails';

export default class AumDetails extends LightningElement {
    @api recordId; 
    @track response;
    @track error;
    noAUMData = false;
    isLoading = false;

    connectedCallback() {
        this.getAUMDetails();
    }

    getAUMDetails() {
    this.isLoading = true;
        fetchAUMDetails({ accId: this.recordId })
            .then((result) => {
                if (result.isSuccess) {
                    let data = JSON.parse(result.responseBody).data;
                    console.log('in data:'+JSON.stringify(data));
                    // Format fields
                    if(data){
                    data.LAST_TRANSACTED_DATE = this.formatDate(data.LAST_TRANSACTED_DATE);
                    data.PAN_AUM = this.formatCurrency(data.PAN_AUM);
                    this.isLoading = false;
                    this.response = data;
                    this.error = null;
                    } else {
                        this.noAUMData = true;
                    }

                    
                } else {
                    this.isLoading = false;
                    console.log('in error');
                    this.response = null;
                    this.error = result.errorMessage;
                }
            })
            .catch((error) => {
                this.response = null;
                this.error = 'Error fetching AUM details: ' + error.body.message;
            });
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const options = { year: 'numeric', month: 'short', day: '2-digit' };
        return new Date(dateStr).toLocaleDateString('en-US', options);
    }

    formatCurrency(value) {
        if (!value) return '₹0';
        return `₹${parseFloat(value).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
    }
}