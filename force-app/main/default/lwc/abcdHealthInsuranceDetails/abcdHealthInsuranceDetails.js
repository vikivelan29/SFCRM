import { LightningElement,api } from 'lwc';
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
                        fieldName: 'policyMaturityDate',
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
                        fieldName: 'premiumAmount',
                        label: 'Premium Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'coverName',
                        label: 'Cover Name',
                        type: 'text'
                    },
                    {
                        fieldName: 'sumInsured',
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
                        fieldName: 'policyPlanName',
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
                    {
                        fieldName: 'annualPremium',
                        label: 'Annual Premium',
                        type: 'currency'
                    }
                ];
export default class AbcdHealthInsuranceDetails extends LightningElement {
    @api hidetails;
    columns = columns;
    @api status;
    @api apiMessage;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.hidetails || this.hidetails.length === 0 || this.hidetails == null);
    }
}
