var React = require('react'),
    flux = require('fluxify');

var PageLabel = React.createClass({
    displayName: 'PageLabel',
    getInitialState: function() {
        return {
            disabled: false,
        }
    },

    componentDidMount: function() {
        var self = this;
  //      console.log('page label componentWillMount')
        flux.stores.docStore.on('change:edited', function(newValue, previousValue) {
                self.setState({disabled: newValue});
        });
    },

    handleClick: function handleClick(page) {
        // обработчик на событие клик, подгружаем связанный документ
 //       alert('click:' + pageName);
        // docTypeId: doc.doc_type, docId:doc.id, pageName:'Lausend id:' + doc.id

        if (this.state.disabled) {
            console.log('page disabled');
            return;
        }

        if (page.docId) {
            console.log('handleClick page.docTypeId %s, page.docId %n');
                var url = "/document/" + page.docTypeId + page.docId;
                document.location.href = url;
        }

    },


    render: function() {
        var className = 'pageLabel';

        return React.createElement(
            'label',
            { className: className, onClick: this.handleClick.bind(this, this.props.children), disabled: this.state.disabled },
            this.props.children.pageName,
            ' '
        );
    }
});

module.exports = PageLabel;