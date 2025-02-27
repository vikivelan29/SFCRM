import { LightningElement,api,track} from 'lwc';
const columns = [
                    {
                        fieldName: 'amcNames',
                        label: 'AMC Name',
                        type: 'text'
                    },
                    {
                        fieldName: 'folioNumber',
                        label: 'Folio Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'schemeNames',
                        label: 'Scheme Name',
                        type: 'text'
                    },
                    {
                        fieldName: 'totalUnits',
                        label: 'Total Units',
                        type: 'text'
                    },
                    {
                        fieldName: 'portfolioValue',
                        label: 'Portfolio Value',
                        type: 'currency'
                    },
                    {
                        fieldName: 'lastTransactionValue',
                        label: 'Last Transaction Value',
                        type: 'currency'
                    },
                    {
                        fieldName: 'lastTransactionQuantity',
                        label: 'Last Transaction Quantity',
                        type: 'number'
                    },
                    {
                        fieldName: 'lastTransactionNAV',
                        label: 'Last Transaction NAV',
                        type: 'text'
                    },
                    {
                        fieldName: 'lastTransactionType',
                        label: 'Last Transaction Type',
                        type: 'text'
                    },
                    {
                        fieldName: 'lastTransactionDate',
                        label: 'Last Transaction Date',
                        type: 'date'
                    },
                ];
export default class AbcdMutualFundDetails extends LightningElement {
    @api mfdetails;
    columns = columns;
    @api status;
    @api apiMessage;
    @api mftransactionDisable = false;

    @track selectedRecord;
    showPopup = false;

    
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.mfdetails || this.mfdetails.length === 0 || this.mfdetails.holdingDetails == null);
    }

    connectedCallback() {
        console.log('Processed mfdetails:', JSON.stringify(this.mfdetails));
        this.mftransactionDisable = true;
        setTimeout(() => {
            if (this.mfdetails) {
                this.mfdetails = {
                    ...this.mfdetails,
                    holdingDetails: this.mfdetails.holdingDetails.map(item => ({
                        ...item,
                        schemeNames: item.schemeNames ? item.schemeNames.join(', ') : ''
                    }))
                };
                console.log('Processed mfdetails:', JSON.stringify(this.mfdetails));
            } else {
                console.error('Error: mfdetails or holdingDetails is undefined.');
            }
        }, 1000);  // Delay for 1 second (adjust if needed)
    }
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedRecord = selectedRows[0].folioNumber;
            this.mftransactionDisable = false;
        }
    }

    /*openChildModal() {
        const childComponent = this.template.querySelector('c-abcd-transaction-history');
        if (childComponent) {
            childComponent.openModal(this.selectedRecord);
        }
    }*/
    openTransactionPopUp(event){
        this.showPopup = true;
    }
    closePopup() {
        this.showPopup = false;
    }

}