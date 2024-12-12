import { LightningElement,api} from 'lwc';
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
                        fieldName: '',
                        label: 'NAV',
                        type: 'text'
                    },
                    {
                        fieldName: '',
                        label: 'Frequency',
                        type: 'text'
                    },
                    {
                        fieldName: '',
                        label: 'Mandate Status',
                        type: 'text'
                    },
                ];
export default class AbcdMutualFundDetails extends LightningElement {
    @api mfdetails;
    columns = columns;
}