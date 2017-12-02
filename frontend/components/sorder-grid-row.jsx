var React = require('react'),
    flux = require('fluxify'),
    ModalPage = require('./modalpage/modalPage.jsx'),
    Select = require('./doc-input-select.jsx'),
    InputText = require('./doc-input-text.jsx'),
    InputNumber = require('./doc-input-number.jsx');

var SorderGridRow = React.createClass({
    getInitialState: function () {
//        console.log('ArvGridRow props', this.props);
        return {
            row: this.props.gridRowData, checked: false, warning:''
        }
    },

    componentDidMount: function() {
    // предварительная проверка
        this.validateForm();
    },

    modalPageClick: function (btnEvent) {
        var components = ['nomid',  'summa', 'proj', 'tunnus'],
            data = [];

        if (btnEvent == 'Ok') {
            // проверка

            // собираем данные для отправки на обработку
            components.map((component) => {
                var componentValue = this.refs[component].state.value;
                if (component == 'proj' || component == 'tunnus') {
                    componentValue = this.refs[component].state.fieldValue;
                }
                console.log('modalPageClick ',component, componentValue )
                data.push({name: component, value: componentValue});
            })
        }
        this.props.modalPageClick(btnEvent, data);
    },

    handleChange: function (e, name) {
        // отслеживаем изменения данных на форме
        console.log('select changed');
        var value = e.target.value;
        if (value !== this.state.row[name] && name == 'nomid') {
            this.refs['summa'].setState({value: 0.00});
        }
        this.validateForm();
    },

    handleInput: function (value, name) {
        // пересчет сумм
        this.recalcRowSumm();

    },

    validateForm: function() {
        // will check values on the form and return string with warning
        var warning = '';
        // только после проверки формы на валидность
        if (!this.refs['nomid'].state.value) warning =  warning + ' кассовая операция';

        if (warning.length > 2 ) {
            // есть проблемы
            warning = 'Отсутсвуют данные:' + warning;
        }
        console.log('validated', warning, this.refs['nomid'].state.value);
        this.setState({checked: true, warning: warning});
    },
    render: function () {

        var row = this.state.row,
            validateMessage = this.state.warning,
            buttonOkReadOnly = validateMessage.length > 0 || !this.state.checked;
//        console.log('row render:',validateMessage, buttonOkReadOnly );
        return (
            <div className='modalPage'>
                <ModalPage
                    modalPageBtnClick={this.modalPageClick}
                    modalPageName='Rea lisamine / parandamine'>
                    <div>
                        <ul>
                        <li>
                            <Select
                                title="Operatsioon: "
                                name='nomid' libs="nomenclature"
                                readOnly={false}
                                value={row.nomid}
                                defaultValue={row.kood}
                                ref='nomid'
                                placeholder='Kassa operatsiooni kood'
                                className='ui-c2'
                                onChange={this.handleChange}/>
                            
                        </li>
                       <li>
                           <InputNumber 
                               title='Summa: ' 
                               name='Summa:' value={row.summa}  
                               disabled="false"
                               bindData={false} ref='summa'
                               className='ui-c2'
                           />
                       </li>
                        <li>
                            <Select
                                title="Projekt:"
                                name='proj'
                                libs="project"
                                readOnly={false}
                                value={row.proj}
                                collId = 'kood'
                                ref='proj'
                                placeholder='Projekt'
                                onChange={this.handleChange}
                                className='ui-c2'
                            />
                        </li>
                        <li>
                            <Select
                                title="Tunnus:"
                                name='tunnus'
                                libs="tunnus"
                                readOnly={false}
                                value={row.tunnus}
                                collId = 'kood'
                                ref='tunnus'
                                placeholder='Lausendi tunnus'
                                onChange={this.handleChange}
                                className='ui-c2'
                            />
                        </li>
                        </ul>
                    </div>
                    <div><span>{validateMessage}</span></div>;
                </ModalPage>
            </div>
        );
    }

});

/*
<div>
    {buttonOkReadOnly ?
        <button disabled> Ok </button>:
        <button onClick={this.modalPageClick.bind(this,'Ok')}> Ok </button>
    }
    <button onClick={this.modalPageClick.bind(this,'Cancel')}> Cancel</button>
</div>
*/


module.exports = SorderGridRow;

/*
 <InputText title='Kood ' name='kood' value={row.kood} readOnly={false}
 disabled="false" ref='kood' ></InputText>
 */
