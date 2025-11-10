/* NOTE:
 * compile with:
 *      `g++ -std=c++17 lcg_reference.cpp -o ./lcg_reference-<OS>_<arch>.exe`
 */
#include <iostream>
#include <fstream>
#include <random>
#include "common.h"

const int gen_n = 16;


int main(int, char **) {

    // Test cases:
    //      Minstd
    //          arbitrary seed & gen gen_n 
    //          arbitrary seed & jump arbitrary & gen gen_n 
    //          arbitrary seed & jump more than modulus & gen gen_n 
    //      Rand48
    //          arbitrary seed & gen gen_n 
    //          arbitrary seed & jump arbitrary & gen gen_n 

    { /* suite 1: minstd_rand */
        std::ofstream ofs("groundtruth/minstd_rand.dat");
        std::minstd_rand gen;
        const uint32_t minstd_rand_modulus = 2147483647U;

        { /* case 1.1 : arbitrary seed, gen gen_n */
            std::cout << "Entering case 1.1" << std::endl;
            uint32_t seed = xmpl_vals32[0];

            ofs << "seed=" << seed
                << ";gen=";

            gen.seed(seed);
            for (int i = 0; i < gen_n; ++i) {
                ofs << gen() << ",";
            }
            ofs << std::endl;
        } { /* case 1.2 : arbitrary seed, arbitrary jump, gen gen_n */
            std::cout << "Entering case 1.2" << std::endl;
            uint32_t seed = xmpl_vals32[1];
            uint32_t jmp = xmpl_vals32[2] >> 2;

            ofs << "seed=" << seed
                << ";jump=" << jmp
                << ";gen=";

            gen.seed(seed);
            gen.discard(jmp);
            for (int i = 0; i < gen_n; ++i) {
                ofs << gen() << ",";
            }
            ofs << std::endl;
        } { /* case 1.3 : arbitrary seed, arbitrary long jump, gen gen_n */
            std::cout << "Entering case 1.3" << std::endl;
            uint32_t seed = xmpl_vals32[2];
            uint32_t jmp = minstd_rand_modulus + 10;

            ofs << "seed=" << seed
                << ";jump=" << jmp
                << ";gen=";

            gen.seed(seed);
            gen.discard(jmp);
            for (int i = 0; i < gen_n; ++i) {
                ofs << gen() << ",";
            }
            ofs << std::endl;
        } 
        ofs.close();
    }


    { /* suite 2: rand48 */
        std::ofstream ofs("groundtruth/rand48.dat");
        using rand48 = std::linear_congruential_engine<std::uint_fast64_t,
              0x5DEECE66DULL, 11ULL, (1ULL << 48)>;
        rand48 gen;

        { /* case 2.1 : arbitrary seed, gen gen_n */
            std::cout << "Entering case 2.1" << std::endl;
            uint64_t seed = xmpl_vals64[0];

            ofs << "seed=" << seed
                << ";gen=";

            gen.seed(seed);
            for (int i = 0; i < gen_n; ++i) {
                ofs << gen() << ",";
            }
            ofs << std::endl;
        } { /* case 2.2 : arbitrary seed, arbitrary jump, gen gen_n */
            std::cout << "Entering case 2.2" << std::endl;
            uint64_t seed = xmpl_vals64[1];
            uint32_t jmp = xmpl_vals32[0];

            ofs << "seed=" << seed
                << ";jump=" << jmp
                << ";gen=";

            gen.seed(seed);
            gen.discard(jmp);
            for (int i = 0; i < gen_n; ++i) {
                ofs << gen() << ",";
            }
            ofs << std::endl;
        }
    }


    return 0;
}
