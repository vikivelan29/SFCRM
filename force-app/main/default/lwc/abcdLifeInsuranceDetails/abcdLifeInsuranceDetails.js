import { LightningElement,api } from 'lwc';
import DATANOTFOUND from "@salesforce/label/c.ABCD_Data_Not_Found_Message";
const columns = [
                    {
                        fieldName: 'applicationNumber',
                        label: 'Application Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'policyNumber',
                        label: 'Policy Number',
                        type: 'text'
                    },                    
                    {
                        fieldName: 'policyStatus',
                        label: 'Policy Status',
                        type: 'text'
                    },
                    {
                        fieldName: 'policyTerm',
                        label: 'Policy Term',
                        type: 'text'
                    },
                    {
                        fieldName: 'maturityDate',
                        label: 'Policy Maturity Date',
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
                        fieldName: 'issueDate',
                        label: 'Policy Issuance Date',
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
                        fieldName: 'policyPremium',
                        label: 'Premium Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'sumAssured',
                        label: 'Insured Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'premiumMode',
                        label: 'Premium Mode',
                        type: 'text'
                    },
                    {
                        fieldName: 'policyType',
                        label: 'Policy Type',
                        type: 'text'
                    },
                    {
                        fieldName: 'planName',
                        label: 'Policy Plan Name',
                        type: 'text'
                    },                    
                    {
                        fieldName: 'policyQuoteNumber',
                        label: 'Policy Quote Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'lastPremiumPaymentDate',
                        label: 'Last Premium payment date',
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
                    /* Annual Premius already present as policy premium and hence not required here.
                    {
                        fieldName: '',
                        label: 'Annual Premium',
                        type: 'currency'
                    }*/
                ];
export default class AbcdLifeInsuranceDetails extends LightningElement {
    @api lidetails;
    columns = columns;

    @api status;
    @api apiMessage;
    dataNotFoundMessage = DATANOTFOUND;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {  

        return !this.apiMessage && (!this.lidetails || !this.lidetails.holdingsDetails);
    }
}