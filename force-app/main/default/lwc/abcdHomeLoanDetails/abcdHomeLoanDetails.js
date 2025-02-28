import { LightningElement,api } from 'lwc';
import DATANOTFOUND from "@salesforce/label/c.ABCD_Data_Not_Found_Message";
const columns = [
                    {
                        fieldName: 'loanAccountNumber',
                        label: 'Loan Account Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'loanStartDate',
                        label: 'Loan Start Date',
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
                    {
                        fieldName: 'loanEndDate',
                        label: 'Loan End Date',
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
                    {
                        fieldName: 'tenor',
                        label: 'Tenor',
                        type: 'text'
                    },
                    {
                        fieldName: 'disbursementDate',
                        label: 'Loan Disbursement Date',
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
                    {
                        fieldName: 'emiAmount',
                        label: 'EMI Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'nextInstallmentDate',
                        label: 'Next Installment Date',
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
                    {
                        fieldName: 'loanType',
                        label: 'Loan Type',
                        type: 'text'
                    },
                    {
                        fieldName: 'businessLOB',
                        label: 'Business LOB',
                        type: 'text'
                    },
                    /* Duplicated
                    {
                        fieldName: 'disbursementDate',
                        label: 'Disbursement Date',
                        type: 'text',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },*/
                    {
                        fieldName: 'sanctionDate',
                        label: 'Sanction Date',
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
                    {
                        fieldName: 'finalAmount',
                        label: 'Final Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'sanctionAmount',
                        label: 'Sanction Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'rateOfInterest',
                        label: 'Rate of Interest',
                        type: 'text',
                    },
                ];
export default class AbcdHomeLoanDetails extends LightningElement {
    @api hfldetails;
    columns = columns;
    dataNotFoundMessage = DATANOTFOUND;
    @api status;
    @api apiMessage;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {  

        return !this.apiMessage && (!this.hfldetails || !this.hfldetails.holdingsDetails);
    }
}