import { LightningElement,api,track} from 'lwc';
import DATANOTFOUND from "@salesforce/label/c.ABCD_Data_Not_Found_Message";
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
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric",
                            day: "2-digit",
                            hour: "2-digit",
                            minute: "2-digit",
                            second:"2-digit"
                        }
                    },
                ];
export default class AbcdMutualFundDetails extends LightningElement {
    @api mfdetails;
    columns = columns;
    @api status;
    @api apiMessage;
    @api mftransactionDisable = false;
    dataNotFoundMessage = DATANOTFOUND;
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