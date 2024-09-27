import { LightningElement ,track,api} from 'lwc';
import getSIPResponse from '@salesforce/apex/ABSLAMC_HoldingsByFolioController.getSIPResponse';
import getHoldingsResponse from '@salesforce/apex/ABSLAMC_HoldingsByFolioController.getHoldingsResponse';
import MyModal from 'c/asf_simpleModal';

const sipColumns = [
    { label: 'Scheme Code', fieldName: 'Scheme_Code', type: 'text', sortable: true },
    { label: 'Scheme Name', fieldName: 'Scheme_Name', type: 'text', sortable: true },
    { label: 'SIP Amount', fieldName: 'Amount', type: 'currency', sortable: true },
    { label: 'SIP Start Date', fieldName: 'SIP_Start_Date', type: 'date', sortable: true },
    { label: 'SIP End Date', fieldName: 'SIP_End_Date', type: 'date', sortable: true },
    { label: 'SIP Frequency', fieldName: 'SIP_Frequency', type: 'text', sortable: true },
    { label: 'SIP Type', fieldName: 'SIP_Type', type: 'text', sortable: true },
    { label: 'SIP Status', fieldName: 'SIP_Status', type: 'text', sortable: true },
    { label: 'CSIP Folio', fieldName: 'CSIP_Folio', type: 'text', sortable: true },
    { label: 'View', fieldName: 'id', type: 'button-icon',initialWidth: 80,
    typeAttributes: {
        label: { fieldName: 'View' },
        name: 'id',
        iconName: 'action:preview'
    },
}
];

const holdingsColumns = [
    { label: 'Scheme Code', fieldName: 'Scheme_Code', type: 'text', sortable: true },
    { label: 'Scheme Name', fieldName: 'Scheme_Name', type: 'text', sortable: true },
    { label: 'Asset Class', fieldName: 'Asset_Class', type: 'text', sortable: true },
    { label: 'Unit Holding', fieldName: 'Unit_Holding', type: 'number', sortable: true },
    { label: 'Holding Amount', fieldName: 'Holding_Amount', type: 'currency', sortable: true },
    { label: 'View', fieldName: 'id', type: 'button-icon',initialWidth: 80,
    typeAttributes: {
        label: { fieldName: 'View' },
        name: 'id',
        iconName: 'action:preview'
    },
}
];
export default class Abamc_getHoldingByFolios extends LightningElement {
    @api recordId;
    //SIP table variables
    @track sipData = [];
    @track paginatedSIPData = [];
    @track sortedBySIP = 'SIP_Start_Date';
    @track sortedDirectionSIP = 'desc';
    @track currentPageSIP = 1;
    @track totalRecordsSIP = 0;
    @track totalPagesSIP = 0;
    @track recordsPerPageSIP = 5;
    loading = true;
    showTable = false;

    sipColumns = sipColumns;
    holdingsColumns = holdingsColumns;

     //Holdings table variables
     @track holdingsData = [];
     @track paginatedHoldingsData = [];
     @track sortedByHoldings = 'Scheme_Code';
     @track sortedDirectionHoldings = 'desc';
     @track currentPageHoldings = 1;
     @track totalRecordsHoldings = 0;
     @track totalPagesHoldings = 0;
     @track recordsPerPageHoldings = 5;

    get isFirstPageSIP() {
        return this.currentPageSIP === 1;
    }

    get isLastPageSIP() {
        return this.currentPageSIP === this.totalPagesSIP;
    }

    get isFirstPageHoldings() {
        return this.currentPageHoldings === 1;
    }

    get isLastPageHoldings() {
        return this.currentPageHoldings === this.totalPagesHoldings;
    }


    connectedCallback() {
        this.loading = true;
        this.fetchSIPData();
        this.fetchHoldingsData();
    }

    async fetchSIPData() {
        this.loading = true;
        try {
            const response = await getSIPResponse({ folioId: this.recordId });
            if (response && response.isSuccess) {
                let parsedData = JSON.parse(response.responseBody).listObject.map(item => ({
                    'Scheme_Code': item.SCHEME_CODE,
                    'Scheme_Name': item.SCHEME_NAME,
                    'Amount': item.SIP_AMOUNT,
                    'SIP_Start_Date': item.SIP_START_DATE,
                    'SIP_End_Date': item.SIP_END_DATE,
                    'SIP_Frequency': item.SIP_FREQUENCY,
                    'SIP_Type': item.SIP_TYPE,
                    'SIP_Status': item.SIP_STATUS,
                    'CSIP_Folio': item.CSIP_FOLIO,
                    'id': item.ID
                }));

                this.sipData = parsedData;
                this.totalRecordsSIP = parsedData.length;
                this.totalPagesSIP = Math.ceil(this.totalRecordsSIP / this.recordsPerPageSIP);
                this.updatePaginatedSIPData();
                this.showTable = true;
            }
        } catch (error) {
            console.error('Error fetching SIP data:', error);
        } finally {
            this.loading = false;
        }
    }


    updatePaginatedSIPData() {
        const startIndex = (this.currentPageSIP - 1) * this.recordsPerPageSIP;
        const endIndex = startIndex + this.recordsPerPageSIP;
        this.paginatedSIPData = this.sipData.slice(startIndex, endIndex);
    }

    handleFirstPageSIP() {
        this.currentPageSIP = 1;
        this.updatePaginatedSIPData();
    }

    handlePrevPageSIP() {
        if (this.currentPageSIP > 1) {
            this.currentPageSIP -= 1;
            this.updatePaginatedSIPData();
        }
    }

    handleNextPageSIP() {
        if (this.currentPageSIP < this.totalPagesSIP) {
            this.currentPageSIP += 1;
            this.updatePaginatedSIPData();
        }
    }

    handleLastPageSIP() {
        this.currentPageSIP = this.totalPagesSIP;
        this.updatePaginatedSIPData();
    }

    handleSortSIP(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBySIP = sortedBy;
        this.sortedDirectionSIP = sortDirection;
        this.sortSIPData(sortedBy, sortDirection);
    }

    sortSIPData(fieldName, sortDirection) {
        this.sipData.sort((a, b) => {
            let aValue = a[fieldName] ? a[fieldName] : '';
            let bValue = b[fieldName] ? b[fieldName] : '';
            return (aValue > bValue ? 1 : -1) * (sortDirection === 'asc' ? 1 : -1);
        });
        this.updatePaginatedSIPData();
    }

    get pageSIPInfo() {
        return `Showing ${this.currentPageSIP} of ${this.totalPagesSIP} pages(s)`;
    }
//Holdings
    async fetchHoldingsData() {
        let response = await getHoldingsResponse({ folioId: this.recordId }).catch(error => {
            console.error(error);
            this.showError('error', 'Oops! Something went wrong', error);
        });

        if (response && response.isSuccess) {
            let parsedData = JSON.parse(response.responseBody).listObject.map(item => ({
                'Scheme_Code': item.SCHEME_CODE,
                'Scheme_Name': item.SCHEME_NAME,
                'Asset_Class': item.ASSET_CLASS,
                'Unit_Holding': item.UNIT_HOLDINGS,
                'Holding_Amount': item.HOLDING_AMOUNT,
                'id': item.ID
            }));

            this.holdingsData = parsedData;
            this.totalRecordsHoldings = parsedData.length;
            this.totalPagesHoldings = Math.ceil(this.totalRecordsHoldings / this.recordsPerPageHoldings);
            this.updatePaginatedHoldingsData();
        }
        this.loading = false;
        this.showTable = true;
    }

    updatePaginatedHoldingsData() {
        const startIndex = (this.currentPageHoldings - 1) * this.recordsPerPageHoldings;
        const endIndex = startIndex + this.recordsPerPageHoldings;
        this.paginatedHoldingsData = this.holdingsData.slice(startIndex, endIndex);
    }

    handleFirstPageHoldings() {
        this.currentPageHoldings = 1;
        this.updatePaginatedHoldingsData();
    }

    handlePrevPageHoldings() {
        if (this.currentPageHoldings > 1) {
            this.currentPageHoldings -= 1;
            this.updatePaginatedHoldingsData();
        }
    }

    handleNextPageHoldings() {
        if (this.currentPageHoldings < this.totalPagesHoldings) {
            this.currentPageHoldings += 1;
            this.updatePaginatedHoldingsData();
        }
    }

    handleLastPageHoldings() {
        this.currentPageHoldings = this.totalPagesHoldings;
        this.updatePaginatedHoldingsData();
    }

    handleSortHoldings(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedByHoldings = sortedBy;
        this.sortedDirectionHoldings = sortDirection;
        this.sortDataHoldings(sortedBy, sortDirection);
    }

    sortDataHoldings(fieldName, sortDirection) {
        this.holdingsData.sort((a, b) => {
            let aValue = a[fieldName] ? a[fieldName] : '';
            let bValue = b[fieldName] ? b[fieldName] : '';
            return (aValue > bValue ? 1 : -1) * (sortDirection === 'asc' ? 1 : -1);
        });
        this.updatePaginatedHoldingsData();
    }

    get pageHoldingsInfo() {
        return `Showing ${this.currentPageHoldings} of ${this.totalPagesHoldings} pages(s)`;
    }



    viewRecordSIP(event) {
        let selectedId = event.detail.row.Scheme_Code;
        let selectedRow = this.sipData.find(item => {
            return item.Scheme_Code == selectedId;
        });
        if (!selectedRow) {
            selectedRow = this.holdingsData.find(item => item.Scheme_Code === selectedId);
        }
        console.log('selected row: ',JSON.stringify(selectedRow));
        MyModal.open({
            content: selectedRow.Scheme_Name,
            header: 'Details',
            label: selectedRow.Scheme_Name,
            footeraction: 'Okay'
        }).then((result) => {
            console.log(result);
        }).catch(error => {
            console.error(error);
        });
    }
}