const SimpleTrade = require('./artifacts/contracts/trade/SimpleTrade.sol/SimpleTrade.json');
const SimpleBet = require('./artifacts/contracts/bets/SimpleBet.sol/SimpleBet.json');

module.exports = [
  {
    uri: 'self-immolate',
    title: 'Self-immolate',
    description: 'Take a chance to rise like a phoenix, or just burn your money.',
    tags: ['bet'],
    features: [],
    json: SimpleBet,
  },
  {
    uri: 'escrow',
    title: 'Escrow',
    description: 'Simple escrow service for a buyer and seller trading goods or services.',
    tags: ['trade', 'freelancing'],
    features: ['escrow', 'arbitration'],
    json: SimpleTrade,
  },
  {
    uri: 'bar-bet',
    title: 'Bar Bet',
    description: 'A simple bet between two parties on an arbitrary future outcome.',
    tags: ['bet'],
    features: ['escrow', 'arbitration'],
    json: SimpleBet,
  },
];
