'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./grid-filter-styles');

const _ = require('lodash');

class GridFilter extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            gridConfig: props.gridConfig, // grid config
            data: props.data
        };

        this.handleChange = this.handleChange.bind(this);
        this.prepareFilterFields = this.prepareFilterFields.bind(this);
    }

    /**
     * Обработчик на изменения инпутов
     * @param e
     */
    handleChange(e) {
        let data = this.state.data;
        let value = e.target.value,
            id = e.target.name,
            index;

        // надо найти элемент массива с данными для этого компонента
        for (let i = 0; i < this.state.data.length; i++) {
            if (this.state.data[i].name === id) {
                index = i;
                break;
            }
        }

        if (index) {
            data[index].value = value;
        }

        this.setState({data: data});

        if (this.props.handler) {
            this.props.handler(data);
        }
        this.forceUpdate();

    }

    componentDidMount() {
        let data = this.state.data;
        this.props.gridConfig.map((row) => {
            let componentType = row.type ? row.type : 'text';

            // props.data пустое, создаем
            data.push({value: null, name: row.id, type: componentType});

        });
        this.setState({data: data});

    }


    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {

        if (JSON.stringify(nextProps.gridConfig) !== JSON.stringify(prevState.gridConfig) ||
            JSON.stringify(nextProps.data) !== JSON.stringify(prevState.data)) {
            return {gridConfig: nextProps.gridConfig, data: nextProps.data};
        } else return null;

    }

    render() {
        // создаст из полей грида компоненты для формирования условий фильтрации
        return <div style={styles.fieldset}>
            {this.prepareFilterFields()}
        </div>
    }

    prepareFilterFields() {
        let data = this.state.data;

        // только поля, которые отмечаны как show:true или явно ка указаны
        const filterFields = this.state.gridConfig.filter(field => {
            if (!('show' in field) || field.show) {
                return field;
            }
        });

        return filterFields.map((row) => {
            let componentType = row.type ? row.type : 'text';
            const obj = data[_.findIndex(data, {name: row.id})];
            let value = _.has(obj, 'value') ? obj.value : '';

            return <div style={styles.formWidget} key={'fieldSet-' + row.id}>
                <div style={styles.formWidgetLabel}>
                    <span>{row.name}</span>
                </div>
                <div style={styles.formWidgetInput}>
                    <input style={styles.input}
                           type={componentType}
                           title={row.name}
                           name={row.id}
                           placeholder={row.name}
                           ref={row.id}
                           value={value || ''}
                           onChange={this.handleChange}
                           defaultValue={this.props.data[row.id]}
                    />
                </div>
            </div>
        });

    }
}

GridFilter.propTypes = {
    gridConfig: PropTypes.array.isRequired,
    data: PropTypes.array.isRequired
};

module.exports = GridFilter;
