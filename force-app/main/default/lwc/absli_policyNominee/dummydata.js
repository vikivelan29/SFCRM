export default function generateData({ amountOfRecords }) {
    return [...Array(amountOfRecords)].map((_, index) => {
        return {
            name: `Nominee (${index+1})`,
            appointee: '',
            nomineeDob: new Date(
                Date.now() + 86400000 * Math.ceil(Math.random() * 20)),
            relationship: 'Parent'
        };
    });
}