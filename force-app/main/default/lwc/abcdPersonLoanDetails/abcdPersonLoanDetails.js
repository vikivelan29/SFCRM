import { LightningElement,api } from 'lwc';
const columns = [
                    {
                        fieldName: 'loanAccountNumber',
                        label: 'Loan Account Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'loanStartDate',
                        label: 'Loan Start Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'loanEndDate',
                        label: 'Loan End Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'tenor',
                        label: 'Tenor',
                        type: 'text'
                    },
                    {
                        fieldName: 'emi',
                        label: 'EMI Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: '',
                        label: 'Next Installment Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
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
                    {
                        fieldName: 'lastDisbursedAmount',
                        label: 'Disbursement Date',
                        type: 'test',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'sanctionDate',
                        label: 'Loan Agreement Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'offerAcceptanceDate',
                        label: 'Offer Acceptance Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'sanctionAmount',
                        label: 'Sanction Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'rateOfInterest',
                        label: 'Rate of Interest',
                        type: 'text'
                    },
                ];
export default class AbcdPersonLoanDetails extends LightningElement {
    @api pldetails;
    columns = columns;
}