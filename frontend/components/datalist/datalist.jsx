'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./datalist-styles');

class DataList extends React.PureComponent {
    constructor(props) {
        super(props);

        let idx = 0;

        if (this.props.value) {
            // we got value, we should find index and initilize idx field
            props.data.forEach((row, index) => {
                if (row[props.bindDataField] === props.value) {
                    // found
                    idx = index;
                }
            });
        }

        this.state = {
            data: props.data,
            index: idx,
            value: props.value
        };
        this.handleLiClick = this.handleLiClick.bind(this);
    }

    render() {
        let data = this.props.data,
            clickedItem = this.state.index;

        return (
            <div ref="datalist">
                <ul ref="datalist-ul">
                    {
                        data.map((item, index) => {
                            let style = Object.assign({}, styles.docList, clickedItem == index ? styles.focused : {}),
                                componentId = 'li-' + index;

                            return (
                                <li key={componentId}
                                    ref={componentId}
                                    onClick={this.handleLiClick.bind(this, index)}
                                    style={style}>
                                    {item.name}
                                </li>)
                        }, this)}
                </ul>
            </div>
        )
    }

    handleLiClick(idx) {
        let value = this.props.data[idx][this.props.bindDataField];
        //ставим метку
        // сохраняем состояние

        this.setState({
            index: idx,
            value: value
        });

        if (this.props.onClickAction) {
            //@todo избавиться от change
            this.props.onClickAction(this.props.name + 'Change', value);
        }
    }

}

DataList.propTypes = {
    value: PropTypes.string,
    data: PropTypes.array
};

DataList.defaultProps = {
    data: [{
        id: 0,
        name: '',
        kood: ''
    }],
    value: null,
    bindDataField: 'id'
}

module.exports = DataList;
