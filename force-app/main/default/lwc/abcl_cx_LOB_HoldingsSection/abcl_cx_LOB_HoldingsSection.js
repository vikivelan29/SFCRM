import { LightningElement, api } from 'lwc';
import ABCL_LOBHoldings from "@salesforce/resourceUrl/ABCL_LOBHoldings";
export default class Abcl_cx_LOB_HoldingsSection extends LightningElement {
    hasFinanceAssets = false;
    hasHealthInsurance = false;
    hasHomeLoan = false;
    hasLifeInsurance = false;
    hasMutualFunds = false;
    hasSecurities = false;
    hasDigital = false;
    @api assetList = [];

    //Logos
    //abcl_AMC = `${ABCL_LOBHoldings}/ABCL_AMC.png`;
    //abcl_FinanceLogo = `${ABCL_LOBHoldings}/ABCLFinance.png`;
    //abcl_healthInsuranceLogo = `${ABCL_LOBHoldings}/ABCl_Health_Insurance.png`;
    //abcl_LifeInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Life_Insurance.png`;
    //abcl_homeLoanLogo = `${ABCL_LOBHoldings}/ABCL_Home_loans.png`;
    //abcl_FinanceLogo = `${ABCL_LOBLogos}/ABCL_Finance.jpg`;
    //abcl_healthInsuranceLogo = `${ABCL_LOBLogos}/ABCL_Health.jpg`;
    //abcl_AMC = `${ABCL_LOBLogos}/ABCL_MF.jpg`;
    //abcl_LifeInsuranceLogo = `${ABCL_LOBLogos}/ABCL_Lifeinsurance.jpg`;
    //abcl_homeLoanLogo = `${ABCL_LOBLogos}/ABCL_Homeloan.jpg`;
    //abcl_securitiesLogo = `${ABCL_LOBLogos}/ABCL_Securities.jpg`;
    abcl_FinanceLogo = `${ABCL_LOBHoldings}/ABCL_Finance.jpg`;
    abcl_healthInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Healthinsurance.jpg`;
    abcl_AMC = `${ABCL_LOBHoldings}/ABCL_MutualFunds.jpg`;
    abcl_LifeInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Lifeinsurance.jpg`;
    abcl_homeLoanLogo = `${ABCL_LOBHoldings}/ABCL_Homeloan.jpg`;
    abcl_securitiesLogo = `${ABCL_LOBHoldings}/ABCL_Stocks.jpg`;
    abcl_DigitalLogo = `${ABCL_LOBHoldings}/ABCL_Digital.jpg`;

    connectedCallback() {
        //Get assets and set the flags
        this.hasFinanceAssets = true;
        this.hasHealthInsurance = true;
        this.hasHomeLoan = true;
        this.hasLifeInsurance = true;
        this.hasMutualFunds = true;
        this.hasSecurities = true;
        this.hasDigital = true;
    }
}