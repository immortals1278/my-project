export class CircularBuffer{
    constructor(size = 60){
        this.size = size;
        this.buffer = new Array(size);
        this.bufferFull = false;
        this.head = 0;
        this.count = 0;
    }

    enqueue(price){
        oldPrice = this.buffer[this.head];
        this.buffer[this.head] = price;
        this.head = (this.head + 1) % this.size;
        if(this.count < this.size){
            this.count++;
        }else{
            this.bufferFull = true;
        }
        return oldPrice;
    }

}