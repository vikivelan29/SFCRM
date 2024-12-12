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
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: 'loanEndDate',
                        label: 'Loan End Date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: 'tenor',
                        label: 'Tenor',
                        type: 'text'
                    },
                    {
                        fieldName: '',
                        label: 'EMI Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: '',
                        label: 'Next Installment Date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
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
                    {
                        fieldName: '',
                        label: 'Disbursement Date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: '',
                        label: 'Loan Agreement Date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: '',
                        label: 'Offer Acceptance Date',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },
                    {
                        fieldName: '',
                        label: 'Sanction Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: '',
                        label: 'Rate of Interest',
                        type: 'text'
                    },
                ];
export default class AbcdPersonLoanDetails extends LightningElement {
    @api pldetails;
    columns = columns;
}