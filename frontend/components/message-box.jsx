var React = require('react');

const MessageBox = React.createClass({
    getInitialState: function() {
        return {show: this.props.show}
    },
    onClick: function() {
//    alert('click');
        console.log('messageBox click');
        this.setState({show:'none'});
    },
    render: function() {
        var show = this.state.show,
            style = {
                display: show,
                position: 'absolute',
                background: 'white',
                marginLeft: '30%',
                marginTop: '5%',
                border:'1px solid black',
                padding: '20px 100px 20px 100px'
            };
        var btnStyle = {
            margin:'20px 10px 10px 10px'
        };

        return (<div className='messageBox' style={style}>
                {this.props.message}
                <div>
                    <input type="button" value = "Ok" style={btnStyle} onClick={this.onClick} className="messageBox-btn"/>
                    <input type="button" value = "Cancel" className="messageBox-btn" style={btnStyle} onClick={this.onClick}/>
                </div>
            </div>
        )
    }
})


module.exports = MessageBox;