// виджет, объединяющий селект и текст. в тексте отражаютмя данные, связанные с селектом
'use strict';

const PropTypes = require('prop-types');
const Select = require('../select/select.jsx');
const ButtonEdit = require('../button-register/button-register-edit/button-register-edit.jsx');
const ButtonAdd = require('../button-register/button-register-add/button-register-add.jsx');
const Text = require('../text-area/text-area.jsx');
const DocContext = require('./../../doc-context.js');
const styles = require('./styles.js');

const React = require('react');

class SelectTextWidget extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value ? props.value : null,
            description: '', // пойдет в текстовую область
            libData: props.data
        };
        this.handleSelectOnChange = this.handleSelectOnChange.bind(this);
        this.handleClick = this.handleClick.bind(this);
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value) {
            return {value: nextProps.value};
        } else return null;
    }


    handleSelectOnChange(name, value) {

        // отработаем событие и поменяем состояние

        this.setState({value: value}, () => {
            this.props.onChange(this.props.name, value);
        });
    }

    /**
     *     кастомный обработчик собютия клик
     */
    handleClick(event) {
        // делаем редайрект на страницц справочника
        if (event === 'edit' || event === 'Muuda') {
            this.props.history.push({
                pathname: `/${DocContext.module}/dokprops/${this.state.value}`,
                state: {dokPropId: DocContext.docTypeId, type: 'text'}
            });

        } else if (event === 'add' || event === 'Lisa') {
            this.props.history.push({
                pathname: `/${DocContext.module}/dokprops/0`,
                state: {dokPropId: DocContext.docTypeId, type: 'text'}
            });
        }

    }

    /**
     * Метод ищет в справочнике описание
     * @param libData
     * @returns {string}
     */
    getDescriptionBySelectValue(libData) {
        // найдем в справочнике описание и установим его состояние
        let libRow = libData.filter((lib) => {

                if (lib.id === this.props.value) {
                    return lib;
                }
            }),
            selg = '',
            selgObject = libRow.length ? libRow[0].details : '';

        for (let property in selgObject) {
            if (selgObject.hasOwnProperty(property)) {
                // интересуют только "собственные" свойства объекта
                selg = selg + property + ':' + selgObject[property];
            }
        }
        return selg;
    }

    render() {
        return (
            <div style={styles.wrapper}>
                <Select className={this.props.className}
                        ref="select"
                        title={this.props.title}
                        name={this.props.name}
                        data={this.props.data}
                        collId={'id'}
                        value={this.state.value || ''}
                        defaultValue={this.props.defaultValue || ''}
                        placeholder={this.props.placeholder || this.props.title}
                        readOnly={this.props.readOnly}
                        onChange={this.handleSelectOnChange}
                />
                {this.state.value ?
                    <ButtonEdit
                        value={'Muuda'}
                        show={this.props.readOnly}
                        onClick={this.handleClick}
                    /> :
                    <ButtonAdd
                        value={'Lisa'}
                        show={this.props.readOnly}
                        onClick={this.handleClick}/>
                }

            </div>
        );
    }
}

SelectTextWidget.propTypes = {
    value: PropTypes.number,
    name: PropTypes.string.isRequired,
    title: PropTypes.string,
    libs: PropTypes.string,
    defaultValue: PropTypes.string,
    readOnly: PropTypes.bool,
    placeholder: PropTypes.string
};


SelectTextWidget.defaultProps = {
    readOnly: false,
    title: ''
};

module.exports = SelectTextWidget;

