address 0x2 {
    module STCNS{

        use 0x1::Vector;
        use 0x1::Signer;
        use 0x1::Option;
        use 0x1::Account;

        struct Global_Data has key,drop,store,copy{
            List :      vector<Distribute_Rule>
        }
        struct Distribute_Rule has key,drop,store,copy{
            Addr :      address,
            Payee:      vector<address>,
            Proportion: vector<u8>
        }
        public fun  get_manager():address{
            return @0xc17e245c8ce8dcfe56661fa2796c98cf
        }
        fun get_index(addr:&address):Option::Option<u64> acquires Global_Data{
            let data = borrow_global<Global_Data>(get_manager());
            let list = *&data.List;
            let i = 0;
            let l = Vector::length<Distribute_Rule>(&list);
            while(i < l){
                
                if((*Vector::borrow<Distribute_Rule>(&list,i)).Addr == *addr){
                    return Option::some<u64>(i) 
                };
                i = i + 1;
            };
            return Option::none<u64>() 
        }

        public fun send(account:&signer ,amount:u128) acquires Global_Data {
            let addr = Signer::address_of(account);
            let index =  get_index(&addr);
            let balance = Account::balance<0x1::STC::STC>(addr);
            assert(balance >= amount , 2001);
            if(Option::is_some<u64>(&index)){
                let list = *&borrow_global<Global_Data>(get_manager()).List;
                let rule = Vector::borrow<Distribute_Rule>(&list,*Option::borrow<u64>(&index));
                let payee = *&rule.Payee;
                let proportion = *&rule.Proportion;
                let i = 0;
                let l = Vector::length<address>(&payee);
                while(i < l){
                    let amount_i = (*Vector::borrow(&proportion,i) as u128 ) * ( amount / 100 );
                    Account::pay_from<0x1::STC::STC>(account,*Vector::borrow(&payee,i),amount_i);
                    i = i + 1;
                };
            }
        }

        public fun add(account:&signer ,addrs:&vector<address>,proportions:&vector<u8>) acquires Global_Data {
            let addr = Signer::address_of(account);
            let index =  get_index(&addr);
            if(!Option::is_some<u64>(&index)){
                let list = *&borrow_global_mut<Global_Data>(get_manager()).List;
            
                let rule = Distribute_Rule {
                    Addr : addr,
                    Payee: *addrs,
                    Proportion:*proportions
                };
                Vector::push_back<Distribute_Rule>(&mut list,rule);
            }
        }
        
        public fun delete(account:&signer) acquires Global_Data{
             let addr = Signer::address_of(account);
            let index =  get_index(&addr);
            if(Option::is_some<u64>(&index)){
                let list = *&borrow_global_mut<Global_Data>(get_manager()).List;
                Vector::remove<Distribute_Rule>(&mut list ,*Option::borrow<u64>(&index));
            }
        }
        public fun init(account:&signer) {
            let addr = Signer::address_of(account);
            assert(addr == get_manager(),2002);
            assert(exists<Distribute_Rule>(get_manager()),2003);
            let data = Global_Data{
                List:   Vector::empty<Distribute_Rule>()
            };
            move_to<Global_Data>(account,data);
        }
    }
}