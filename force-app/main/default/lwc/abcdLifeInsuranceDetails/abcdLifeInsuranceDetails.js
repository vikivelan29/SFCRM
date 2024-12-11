import { LightningElement,api } from 'lwc';
const columns = [
                    {
                        fieldName: '',
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
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: 'issueDate',
                        label: 'Policy Issuance Date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
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
                        fieldName: '',
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
                        fieldName: '',
                        label: 'Policy Quote Number',
                        type: 'text'
                    },
                    {
                        fieldName: '',
                        label: 'Last Premium payment date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: '',
                        label: 'Annual Premium',
                        type: 'currency'
                    }
                ];
export default class AbcdLifeInsuranceDetails extends LightningElement {
    @api lidetails;
    columns = columns;
}